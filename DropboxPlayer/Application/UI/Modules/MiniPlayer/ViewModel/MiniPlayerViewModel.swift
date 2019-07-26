//
//  MiniPlayerViewModel.swift
//  DropboxPlayer
//
//  Created by Oleg on 07/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxCocoa

protocol MiniPlayerViewModelDelegate: class {
    func miniPlayerViewModelDidRequestToOpenFullscreen(_ viewModel: MiniPlayerViewModel)
}

protocol MiniPlayerViewModel: class {
    
    var trackInfo: BehaviorRelay<TrackInfo?> { get }
    var playbackInfo: BehaviorRelay<PlaybackInfo> { get }
    var isPlaybackAvailable: BehaviorRelay<Bool> { get }
    var isTimeChangingInProgress: Bool { get }
    
    func pause()
    func play()
    func restart()
    func switchToNextTrack()
    func switchToPrevTrack()
    func seek(to position: PlaybackPosition)
    
    func openFullscreenPlayer()
}

class MiniPlayerViewModelImplementation: MiniPlayerViewModel {
    
    var trackInfo: BehaviorRelay<TrackInfo?> {
        return cloudPlayer.trackInfo
    }
    var playbackInfo: BehaviorRelay<PlaybackInfo> {
        return cloudPlayer.playbackInfo
    }
    var isTimeChangingInProgress: Bool {
        return cloudPlayer.isTimeChangingInProgress
    }
    var isPlaybackAvailable: BehaviorRelay<Bool> {
        return cloudPlayer.isPlaybackAvailable
    }
    
    weak var delegate: MiniPlayerViewModelDelegate?
    
    private let cloudPlayer: DropboxPlayer
    
    // MARK: - Init
    
    init(with cloudPlayer: DropboxPlayer) {
        self.cloudPlayer = cloudPlayer
    }
    
    // MARK: - Public methods
    
    func restart() {
        cloudPlayer.restart()
    }
    
    func seek(to position: PlaybackPosition) {
        cloudPlayer.seek(to: position)
    }
    
    func switchToPrevTrack() {
        cloudPlayer.switchToPrevTrack()
    }
    
    func switchToNextTrack() {
        cloudPlayer.switchToNextTrack()
    }
    
    func pause() {
        cloudPlayer.pause()
    }
    
    func play() {
        cloudPlayer.play()
    }
    
    func openFullscreenPlayer() {
        delegate?.miniPlayerViewModelDidRequestToOpenFullscreen(self)
    }
}
