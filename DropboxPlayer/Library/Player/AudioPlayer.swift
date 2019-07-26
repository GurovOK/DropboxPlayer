//
//  AudioPlayer.swift
//  DropboxPlayer
//
//  Created by Oleg on 11/05/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import AVKit

protocol AudioPlayerDelegate: class {
    
    func audioPlayer(_ player: AudioPlayer,
                     didChangeCurrentItem item: AudioPlayerItem?)
    func audioPlayer(_ player: AudioPlayer,
                     didReceiveMetadata metadata: AudioPlayerItemMetadata,
                     for item: AudioPlayerItem)
}

@objc enum AudioPlayerState: Int {
    
    case noItemToPlay
    case preparing
    case readyToPlay
    case playing
    case paused
    case finished
    case failed
}

struct AudioPlayerItemMetadata {
    let title: String?
    let album: String?
    let artworkData: Data?
}

struct AudioPlayerItem: Equatable {
    let url: URL
}

class AudioPlayer: NSObject {
    
    private struct Constants {
        static let timeObserverInterval: TimeInterval = 1
        static let metadataKey = "metadata"
        static let titleMetadataIdentifier = AVMetadataIdentifier.commonIdentifierTitle
        static let albumMetadataIdentifier = AVMetadataIdentifier.commonIdentifierAlbumName
        static let artworkMetadataIdentifier = AVMetadataIdentifier.commonIdentifierArtwork
    }
    
    // MARK: - Public propreties
    
    @objc private(set) dynamic var isTimeChangingInProgress: Bool = false
    @objc private(set) dynamic var isBuffering: Bool = false
    @objc private(set) dynamic var state: AudioPlayerState = .noItemToPlay
    @objc private(set) dynamic var currentTime: TimeInterval = 0
    
    weak var delegate: AudioPlayerDelegate?
    var hasNextItem: Bool {
        guard let item = currentItem,
            let index = items.firstIndex(of: item) else { return false }
        return items.index(after: index) < items.count
    }
    var hasPreviousItem: Bool {
        guard let item = currentItem,
            let index = items.firstIndex(of: item) else { return false }
        return items.index(before: index) >= 0
    }
    var duration: TimeInterval? {
        return player.currentItem?.duration.seconds
    }
    var error: Error? {
        return player.currentItem?.error
    }
    
    // MARK: - Private properties
    
    private var items: [AudioPlayerItem] = []
    private(set) var currentItem: AudioPlayerItem? {
        didSet {
            if oldValue != currentItem {
                delegate?.audioPlayer(self, didChangeCurrentItem: currentItem)
                loadCurrentItemMetadata()
            }
        }
    }
    private var player: AVQueuePlayer = AVQueuePlayer(items: [])
    private let assetsLoader: AudioAssetsLoader
    
    private var timeObserver: Any?
    private var rateObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var currentItemObserver: NSKeyValueObservation?
    private var playbackFinishedObserver: NSObjectProtocol?
    private var timedMetadataObserver: NSKeyValueObservation?
    
    // MARK: - Init
    
    init(assetsLoader: AudioAssetsLoader) {
        self.assetsLoader = assetsLoader
        super.init()
        setupAudioSession()
    }
    
    deinit {
        removeCurrentItemObserver()
        removeStatusObserver()
        removeCurrentTimeObserver()
        removeRateObserver()
    }
    
    // MARK: - Public methods
    
    func setItems(_ items: [AudioPlayerItem], initialItemIndex: Int = 0) {
        resetPlaybackState()
        self.items = items
        switchToItem(atIndex: initialItemIndex)
    }
    
    func previousTrack() {
        guard let currentItem = currentItem,
            let index = items.firstIndex(of: currentItem) else {
                return
        }
        let prevIndex = items.index(before: index)
        switchToItem(atIndex: prevIndex)
    }
    
    func nextTrack() {
        if state == .failed,
            let currentItem = currentItem,
            let index = items.firstIndex(of: currentItem) {
            switchToItem(atIndex: index + 1)
        } else {
            player.advanceToNextItem()
        }
    }
    
    func play() {
        guard currentItem != nil else { return }
        player.play()
        state = .playing
    }
    
    func pause() {
        player.pause()
        state = .paused
    }
    
    func restart() {
        guard let item = currentItem,
            let index = items.firstIndex(of: item) else { return }
        switchToItem(atIndex: index)
    }
    
    func seekTo(time: TimeInterval, completion: @escaping () -> Void) {
        guard let durationTime = player.currentItem?.duration else { return }
        let playerTime = CMTime(seconds: time, preferredTimescale: durationTime.timescale)
        if playerTime.isValid {
            player.seek(
                to: playerTime,
                completionHandler: { _ in
                    self.currentTime = time
                    completion()
            })
        }
    }
    
    func switchToItem(atIndex index: Int) {
        guard index >= 0, index < items.count else {
            return
        }
        let newItems = items[index..<items.count]
        handle(items: Array(newItems))
    }
    
    // MARK: - Private methods
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback)
    }
    
    private func handle(items: [AudioPlayerItem]) {
        removeCurrentItemObserver()
        removeStatusObserver()
        removeCurrentTimeObserver()
        removeRateObserver()
        player.removeAllItems()
        currentTime = 0
        guard !items.isEmpty else {
            return
        }
        let playerItems: [AVPlayerItem] = items.map {
            let asset = assetsLoader.assetForURL($0.url)
            return AVPlayerItem(asset: asset)
        }
        player = AVQueuePlayer(items: playerItems)
        addCurrentItemObserver()
        addCurrentTimeObserver()
        addRateObserver()
    }
    
    private func resetPlaybackState() {
        isBuffering = false
        currentTime = 0
        isTimeChangingInProgress = false
    }

    private func updateCurrentItemStatus() {
        guard let item = player.currentItem else { return }
        switch item.status {
        case .readyToPlay:
            state = .readyToPlay
        case .failed:
            removeCurrentItemObserver()
            player.removeAllItems()
            state = .failed
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Metadata

    private func loadCurrentItemMetadata() {
        guard let asset = player.currentItem?.asset,
            let currentItem = currentItem else { return }
        asset
            .loadValuesAsynchronously(
                forKeys: [Constants.metadataKey],
                completionHandler: {
                    guard !asset.metadata.isEmpty else { return }
                    let title = AVMetadataItem
                        .metadataItems(from: asset.metadata,
                                       filteredByIdentifier: Constants.titleMetadataIdentifier).first?.stringValue
                    let album = AVMetadataItem
                        .metadataItems(from: asset.metadata,
                                       filteredByIdentifier: Constants.albumMetadataIdentifier).first?.stringValue
                    let artworkData = AVMetadataItem
                        .metadataItems(from: asset.metadata,
                                       filteredByIdentifier: Constants.artworkMetadataIdentifier).first?.dataValue
                    let metadata = AudioPlayerItemMetadata(title: title, album: album, artworkData: artworkData)
                    DispatchQueue.main.async { [weak self] in
                        self?.handle(metadata, for: currentItem)
                    }
                    
        })
    }
    
    private func handle(_ metadata: AudioPlayerItemMetadata, for item: AudioPlayerItem) {
        delegate?.audioPlayer(self, didReceiveMetadata: metadata, for: item)
    }

    // MARK: - Player observers
    
    private func addCurrentItemObserver() {
        currentItemObserver = player.observe(
            \.currentItem,
            options: [.initial, .new]) { [weak self] player, _ in
                guard let self = self else { return }
                self.removeStatusObserver()
                self.currentTime = 0
                if let urlAsset = player.currentItem?.asset as? AVURLAsset,
                    let index = self.items.firstIndex(where: { $0.url == urlAsset.url }) {
                    self.currentItem = self.items.item(at: index)
                    self.state = .preparing
                    self.addStatusObserver()
                    self.updateCurrentItemStatus()
                } else {
                    self.currentItem = nil
                    self.state = .finished
                }
        }
    }
    
    private func removeCurrentItemObserver() {
        currentItemObserver?.invalidate()
        currentItemObserver = nil
    }
    
    private func addRateObserver() {
        rateObserver = player.observe(
            \.rate,
            options: [.initial, .new]) { [weak self] player, _ in
                guard let self = self else { return }
                if self.state == .playing, player.rate == 0 {
                    self.state = .paused
                }
        }
    }
    
    private func removeRateObserver() {
        rateObserver?.invalidate()
        rateObserver = nil
    }
    
    private func addStatusObserver() {
        guard let item = player.currentItem else { return }
        statusObserver = item.observe(\.status) { [weak self] item, _ in
            self?.updateCurrentItemStatus()
        }
    }
    
    private func removeStatusObserver() {
        statusObserver?.invalidate()
        statusObserver = nil
    }
 
    private func addCurrentTimeObserver() {
        let interval = CMTime(seconds: Constants.timeObserverInterval,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: mainQueue) { [weak self] time in
                self?.currentTime = time.seconds
        }
    }
    
    private func removeCurrentTimeObserver() {
        guard let observer = timeObserver else { return }
        player.removeTimeObserver(observer)
        timeObserver = nil
    }
}
