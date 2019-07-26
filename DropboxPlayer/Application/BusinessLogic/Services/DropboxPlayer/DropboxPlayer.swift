//
//  DropboxPlayer.swift
//  DropboxPlayer
//
//  Created by Oleg on 07/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum PlaybackState {
    case unknown
    case preparing
    case readyToPlay
    case paused
    case playing
    case finished
    case failed
}

typealias PlaybackPosition = Double

protocol DropboxPlayer {
    
    var trackInfo: BehaviorRelay<TrackInfo?> { get }
    var timeInfo: BehaviorRelay<TrackTimeInfo?> { get }
    var playbackInfo: BehaviorRelay<PlaybackInfo> { get }
    var isBuffering: BehaviorRelay<Bool> { get }
    var isPlaybackAvailable: BehaviorRelay<Bool> { get }
    
    var isTimeChangingInProgress: Bool { get }
    
    func pause()
    func play()
    func restart()
    func switchToNextTrack()
    func switchToPrevTrack()
    func seek(to position: PlaybackPosition)
    
    func setPlaylist(_ playlist: Playlist?)
}

class DropboxPlayerImplementation: DropboxPlayer {
    
    private struct Constants {
        static let timeSavingDelay: TimeInterval = 10
    }
    
    // MARK: - Properties
    
    let trackInfo = BehaviorRelay<TrackInfo?>(value: nil)
    let timeInfo = BehaviorRelay<TrackTimeInfo?>(value: nil)
    let playbackInfo = BehaviorRelay<PlaybackInfo>(value: .empty)
    let isBuffering = BehaviorRelay<Bool>(value: false)
    let isPlaybackAvailable = BehaviorRelay<Bool>(value: false)
    
    private(set) var isTimeChangingInProgress: Bool = false
    
    private var playbackState: PlaybackState = .unknown {
        didSet {
            updatePlaybackInfo()
        }
    }
    private let remoteCommandCenter: PlayerRemoteCommandCenter
    private let audioFileURLService: AudioFileURLService
    private let databaseService: DatabaseService
    private let disposeBag = DisposeBag()
    
    private var currentItem: PlaylistItem? {
        guard let playerItem = player.currentItem else { return nil }
        let item = currentPlaylist?.items.first(where: {
            let url = urlFactory.makeAudioFileResourceURL(from: $0.audioFile)
            return url == playerItem.url
        })
        return item
    }
    private var currentPlaylist: Playlist? {
        didSet {
            isPlaybackAvailable.accept(currentPlaylist != nil)
        }
    }
    private var isPlaybackStarted = false
    private lazy var player: AudioPlayer = {
        let player = AudioPlayer(assetsLoader: AudioAssetsLoader(audioFileURLService: audioFileURLService))
        player.delegate = self
        return player
    }()
    private var playerStatusObservation: NSKeyValueObservation?
    private var playerCurrentTimeObservation: NSKeyValueObservation?
    private let urlFactory: AudioAssetURLFactory
    private var lastTimeSavingTime: TimeInterval = 0
    
    // MARK: - Init
    
    init(with audioFileURLService: AudioFileURLService,
         databaseService: DatabaseService,
         urlFactory: AudioAssetURLFactory = AudioAssetURLFactory(),
         remoteCommandCenter: PlayerRemoteCommandCenter) {
        
        self.remoteCommandCenter = remoteCommandCenter
        self.audioFileURLService = audioFileURLService
        self.databaseService = databaseService
        self.urlFactory = urlFactory
        addWillTerminateObserver()
        setupPlayerRemoteCommandCenter()
        bindToAudioPlayer()
    }
    
    deinit {
        removeWillTerminateObserver()
        playerStatusObservation?.invalidate()
        playerCurrentTimeObservation?.invalidate()
    }
    
    // MARK: - Public methods
    
    func pause() {
        isPlaybackStarted = false
        if playbackState == .playing {
            saveCurrentTrackPlaybackTime(player.currentTime)
        }
        player.pause()
    }
    
    func play() {
        isPlaybackStarted = true
        var playbackTime: TimeInterval = 0
        if let item = currentItem,
            case let .playback(time) = item.state {
            playbackTime = time
        }
        play(fromTime: playbackTime)
        updatePlaybackInfo()
        saveCurrentTrackPlaybackTime(playbackTime)
    }
    
    func switchToPrevTrack() {
        player.previousTrack()
    }
    
    func switchToNextTrack() {
        player.nextTrack()
    }
    
    func setPlaylist(_ playlist: Playlist?) {
        currentPlaylist = playlist
        isPlaybackStarted = false
        if let playlist = playlist {
            let items: [AudioPlayerItem] = playlist.items.compactMap {
                guard let url = self.urlFactory.makeAudioFileResourceURL(from: $0.audioFile) else { return nil }
                return AudioPlayerItem(url: url)
            }
            var currentTrackIndex = 0
            if let currentTrack = playlist.currentTrack,
                let index = playlist.items.lastIndex(of: currentTrack) {
                currentTrackIndex = index
            }
            player.setItems(items, initialItemIndex: currentTrackIndex)
        } else {
            player.setItems([])
        }
    }
    
    func restart() {
        player.restart()
    }
    
    func seek(to position: PlaybackPosition) {
        guard let duration = player.duration, duration > 0 else {
            return
        }
        let time = position * duration
        
        isTimeChangingInProgress = true
        seek(toTime: time) {
            self.isTimeChangingInProgress = false
        }
    }
    
    // MARK: - Private methods
    
    private func setupPlayerRemoteCommandCenter() {
        remoteCommandCenter.updatePlaybackControls(with: playbackInfo.value)
        remoteCommandCenter.actionHandler = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .play:
                self.play()
            case .pause:
                self.pause()
            case .fastForward:
                self.switchToNextTrack()
            case .rewind:
                self.switchToPrevTrack()
            case .changePlaybackPosition(let time):
                self.seek(toTime: time)
            }
        }
    }
    
    private func bindToAudioPlayer() {
        playerStatusObservation = player
            .observe(\.state,
                     options: [.initial, .new],
                     changeHandler: { [weak self] player, _ in
                        self?.handle(playerState: player.state)
            })
        playerCurrentTimeObservation = player
            .observe(\.currentTime,
                     options: [.initial, .new],
                     changeHandler: { [weak self] player, _ in
                        self?.handle(playbackTime: player.currentTime)
            })
    }
    
    private func handle(playbackTime: TimeInterval) {
        guard currentItem != nil else {
            return
        }
        var timeInfo: TrackTimeInfo?
        let currentTime = player.currentTime
        if let duration = player.duration,
            duration != .nan {
            timeInfo = TrackTimeInfo(currentTime: currentTime, duration: duration)
        }
        setTimeInfo(timeInfo)
        if Date().timeIntervalSinceReferenceDate - lastTimeSavingTime >= Constants.timeSavingDelay {
            saveCurrentTrackPlaybackTime(playbackTime)
        }
    }
    
    private func handle(playerState: AudioPlayerState) {
        switch playerState {
        case .noItemToPlay:
            break
        case .preparing:
            playbackState = .preparing
        case .readyToPlay:
            playbackState = .readyToPlay
            var playbackTime: TimeInterval = 0
            if let item = currentItem,
                case let .playback(time) = item.state {
                playbackTime = time
            }
            if isPlaybackStarted {
                play(fromTime: playbackTime)
            } else {
                seek(toTime: playbackTime)
            }
        case .playing:
            playbackState = .playing
        case .paused:
            playbackState = .paused
        case .failed:
            playbackState = .failed
        case .finished:
            isPlaybackStarted = false
            playbackState = .finished
            resetPlaylistPlayback()
            setPlaylist(currentPlaylist)
        }
    }
    
    private func saveCurrentTrackPlaybackTime(_ time: TimeInterval) {
        guard let playlist = currentPlaylist,
            let currentTrack = currentItem else {
                return
        }
        playlist.items.forEach {
            if $0 == currentTrack {
                $0.state = .playback(time)
            } else {
                $0.state = .undefined
            }
        }
        databaseService.save(playlist: playlist)
        lastTimeSavingTime = Date().timeIntervalSinceReferenceDate
    }
    
    private func play(fromTime time: TimeInterval = 0) {
        let playBlock = {
            self.player.play()
        }
        if time > 0 {
            seek(toTime: time) {
                playBlock()
            }
        } else {
            playBlock()
        }
    }
    
    private func seek(toTime time: TimeInterval, completion: (() -> Void)? = nil) {
        player.seekTo(time: time) {
            completion?()
        }
    }
    
    private func updateCurrentTrackInfo() {
        setTrackInfo(nil)
        
        if let playlist = currentPlaylist,
            let item = currentItem {
            let index = playlist.items.firstIndex(of: item) ?? 0
            let info = TrackInfo(trackFileName: item.audioFile.name,
                                 playlistName: playlist.name,
                                 positionInfo: (index, playlist.items.count))
            setTrackInfo(info)
        }
        updatePlaybackInfo()
    }
    
    private func setTrackInfo(_ info: TrackInfo?) {
        trackInfo.accept(info)
        remoteCommandCenter.update(with: info)
    }
    
    private func setTimeInfo(_ info: TrackTimeInfo?) {
        timeInfo.accept(info)
        remoteCommandCenter.update(with: info)
    }
    
    private func updatePlaybackInfo() {
        let info = PlaybackInfo(with: playbackState,
                                playbackRequested: isPlaybackStarted,
                                nextTrackAvailable: player.hasNextItem,
                                previousTrackAvailable: player.hasPreviousItem)
        playbackInfo.accept(info)
        remoteCommandCenter.updatePlaybackControls(with: info)
    }
    
    private func resetPlaylistPlayback() {
        guard let playlist = currentPlaylist else { return }
        playlist.items.forEach {
            $0.state = .undefined
        }
        databaseService.save(playlist: playlist)
    }
}

// MARK: - WillTerminateNotification observer
extension DropboxPlayerImplementation {
    
    private func addWillTerminateObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }
    
    private func removeWillTerminateObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willTerminateNotification,
                                                  object: nil)
    }
    
    @objc private func appWillTerminate() {
        guard player.state == .playing else { return }
        saveCurrentTrackPlaybackTime(player.currentTime)
    }
}

// MARK: - AudioPlayerDelegate
extension DropboxPlayerImplementation: AudioPlayerDelegate {
    
    func audioPlayer(_ player: AudioPlayer,
                     didChangeCurrentItem item: AudioPlayerItem?) {
        var currentTime: TimeInterval = 0
        if case let .playback(time)? = currentItem?.state {
            currentTime = time
        }
        updateCurrentTrackInfo()
        saveCurrentTrackPlaybackTime(currentTime)
    }
    
    func audioPlayer(_ player: AudioPlayer,
                     didReceiveMetadata metadata: AudioPlayerItemMetadata,
                     for item: AudioPlayerItem) {
        guard let playlist = currentPlaylist,
            let currentItem = currentItem,
            let url = urlFactory.makeAudioFileResourceURL(from: currentItem.audioFile),
            url == item.url else { return }
        
        let index = playlist.items.firstIndex(of: currentItem) ?? 0
        setTrackInfo(TrackInfo(playlistName: playlist.name,
                               metadata: metadata,
                               positionInfo: (index, playlist.items.count)))
    }
}
