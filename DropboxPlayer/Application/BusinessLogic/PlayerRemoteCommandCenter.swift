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
    private lazy var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private var artworkChangeWorkItem: DispatchWorkItem?
    
    // MARK: - Public methods
    
    func updatePlaybackControls(with playbackInfo: PlaybackInfo) {
        commandCenter.playCommand.isEnabled = !playbackInfo.isPlaying
        commandCenter.pauseCommand.isEnabled = playbackInfo.isPlaying
        commandCenter.nextTrackCommand.isEnabled = playbackInfo.nextTrackAvailable
        commandCenter.previousTrackCommand.isEnabled = playbackInfo.previousTrackAvailable
        commandCenter.changePlaybackPositionCommand.isEnabled = playbackInfo.canEditPlaybackPosition
    }
    
    func update(with trackInfo: TrackInfo?) {
        var info = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        info[MPMediaItemPropertyTitle] = trackInfo?.trackName ?? ""
        info[MPMediaItemPropertyAlbumTitle] = trackInfo?.albumName ?? ""
        info.removeValue(forKey: MPMediaItemPropertyArtwork)
        nowPlayingInfoCenter.nowPlayingInfo = info
        updateArtwork(with: trackInfo)
    }
    
    func update(with timeInfo: TrackTimeInfo?) {
        var info = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        info[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1.0)
        info[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: timeInfo?.duration ?? 0)
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: timeInfo?.currentTime ?? 0)
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
    
    private func updateArtwork(with trackInfo: TrackInfo?) {
        artworkChangeWorkItem?.cancel()
        artworkChangeWorkItem = nil
        let updateArtwork: (UIImage?) -> Void = { [weak self] image in
            guard let self = self else { return }
            var info = self.nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
            if let image = image {
                let artwork = MPMediaItemArtwork(boundsSize: image.size,
                                                 requestHandler: { size -> UIImage in
                    return image
                })
                info[MPMediaItemPropertyArtwork] = artwork
                self.nowPlayingInfoCenter.nowPlayingInfo = info
            }
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
