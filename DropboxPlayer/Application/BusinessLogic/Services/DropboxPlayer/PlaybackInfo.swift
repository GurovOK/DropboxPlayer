//
//  PlaybackInfo.swift
//  DropboxPlayer
//
//  Created by Oleg on 15/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

struct PlaybackInfo {
    
    let isPlaying: Bool
    let isPreparing: Bool
    let isPlaybackFailed: Bool
    let playbackAvailable: Bool
    let nextTrackAvailable: Bool
    let previousTrackAvailable: Bool
    let canEditPlaybackPosition: Bool
    
    static var empty: PlaybackInfo {
        return PlaybackInfo(isPlaying: false,
                            isPreparing: false,
                            isPlaybackFailed: false,
                            playbackAvailable: false,
                            nextTrackAvailable: false,
                            previousTrackAvailable: false,
                            canEditPlaybackPosition: false)
    }
}


extension PlaybackInfo {
    
    init(with state: PlaybackState,
         playbackRequested: Bool,
         nextTrackAvailable: Bool,
         previousTrackAvailable: Bool) {
        var playbackAvailable = false
        var isPlaying = false
        var isPreparing = false
        var canEditPlaybackPosition = false
        var isPlaybackFailed = false
        switch state {
        case .paused:
            isPlaying = false
            playbackAvailable = true
            canEditPlaybackPosition = true
        case .playing:
            isPlaying = true
            playbackAvailable = true
            canEditPlaybackPosition = true
        case .preparing:
            isPlaying = playbackRequested
            isPreparing = true
            playbackAvailable = true
        case .readyToPlay:
            playbackAvailable = true
            canEditPlaybackPosition = true
        case .failed:
            isPlaybackFailed = true
        case .unknown, .finished:
            break
        }
        self.isPlaying = isPlaying
        self.isPreparing = isPreparing
        self.isPlaybackFailed = isPlaybackFailed
        self.playbackAvailable = playbackAvailable
        self.nextTrackAvailable = nextTrackAvailable
        self.previousTrackAvailable = previousTrackAvailable
        self.canEditPlaybackPosition = canEditPlaybackPosition
    }
    
}
