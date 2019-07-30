//
//  PlayerRemoteCommandCenter.swift
//  DropboxPlayer
//
//  Created by Oleg on 06/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import MediaPlayer

class PlayerRemoteCommandCenter: NSObject {

    typealias ActionHandler = (_ action: PlayerRemoteCommandCenterAction) -> Void
    
    enum PlayerRemoteCommandCenterAction {
        case play
        case pause
        case rewind
        case fastForward
        case changePlaybackPosition(toTime: TimeInterval)
    }
    
    // MARK: - Properties
    
    var actionHandler: ActionHandler?
    
    private lazy var commandCenter: MPRemoteCommandCenter = {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.previousTrackCommand.addTarget(
            self,
            action: #selector(rewindButtonTapped))
        commandCenter.nextTrackCommand.addTarget(
            self,
            action: #selector(fastForwardButtonTapped))
        commandCenter.playCommand.addTarget(
            self,
            action: #selector(playButtonTapped))
        commandCenter.pauseCommand.addTarget(
            self,
            action: #selector(pauseButtonTapped))
        commandCenter.changePlaybackPositionCommand.addTarget(
            self,
            action: #selector(changePlaybackPosition(event:)))
        return commandCenter
    }()
    private var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private var artworkChangeWorkItem: DispatchWorkItem?
    private var lastTrackInfo: TrackInfo?
    private var lastTimeInfo: TrackTimeInfo?
    private var nowPlayingInfo = [String: Any]()
    
    // MARK: - Public methods
    
    func updatePlaybackControls(with playbackInfo: PlaybackInfo) {
        commandCenter.playCommand.isEnabled = !playbackInfo.isPlaying
        commandCenter.pauseCommand.isEnabled = playbackInfo.isPlaying
        commandCenter.nextTrackCommand.isEnabled = playbackInfo.nextTrackAvailable
        commandCenter.previousTrackCommand.isEnabled = playbackInfo.previousTrackAvailable
        commandCenter.changePlaybackPositionCommand.isEnabled = playbackInfo.canEditPlaybackPosition
    }
    
    func update(with trackInfo: TrackInfo?) {
        defer {
            lastTrackInfo = trackInfo
        }
        guard lastTrackInfo != trackInfo else { return }
        if let trackInfo = trackInfo {
            nowPlayingInfo[MPMediaItemPropertyTitle] = trackInfo.trackName
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = trackInfo.albumName
            nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = NSNumber(value: trackInfo.positionInfo.trackIndex)
            nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount] = NSNumber(value: trackInfo.positionInfo.totalTracksCount)
        } else {
            nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyTitle)
            nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyAlbumTitle)
            nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyAlbumTrackCount)
            nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyAlbumTrackNumber)
        }
        nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyArtwork)
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        updateArtwork(with: trackInfo)
    }
    
    func update(with timeInfo: TrackTimeInfo?) {
        defer {
            lastTimeInfo = timeInfo
        }
        guard lastTimeInfo != timeInfo else { return }
        if let timeInfo = timeInfo {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1.0)
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: timeInfo.duration)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: timeInfo.currentTime)
        } else {
            nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyPlaybackDuration)
            nowPlayingInfo.removeValue(forKey: MPNowPlayingInfoPropertyPlaybackRate)
            nowPlayingInfo.removeValue(forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateArtwork(with trackInfo: TrackInfo?) {
        artworkChangeWorkItem?.cancel()
        artworkChangeWorkItem = nil
        let updateArtwork: (UIImage?) -> Void = { [weak self] image in
            guard let self = self else { return }
            if let image = image {
                let artwork = MPMediaItemArtwork(boundsSize: image.size,
                                                 requestHandler: { size -> UIImage in
                    return image
                })
                self.nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            } else {
                self.nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyArtwork)
            }
            self.nowPlayingInfoCenter.nowPlayingInfo = self.nowPlayingInfo
        }
        if let data = trackInfo?.artworkData {
            let workItem = DispatchWorkItem(block: {
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    updateArtwork(image)
                }
            })
            artworkChangeWorkItem = workItem
            DispatchQueue.global().async(execute: workItem)
        } else {
            updateArtwork(nil)
        }
    }
    
    // MARK: - Actions
    
    @objc private func pauseButtonTapped() {
        actionHandler?(.pause)
    }
    
    @objc private func playButtonTapped() {
        actionHandler?(.play)
    }
    
    @objc private func fastForwardButtonTapped() {
        actionHandler?(.fastForward)
    }
    
    @objc private func rewindButtonTapped() {
        actionHandler?(.rewind)
    }
    
    @objc private func changePlaybackPosition(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard commandCenter.changePlaybackPositionCommand.isEnabled else {
            return .commandFailed
        }
        actionHandler?(.changePlaybackPosition(toTime: event.positionTime))
        return .success
    }
}
