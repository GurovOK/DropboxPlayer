//
//  PlayerViewModel.swift
//  DropboxPlayer
//
//  Created by Oleg on 23/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol PlayerViewModelDelegate: class {

    func playerViewModelDidRequestToCollapse(_ viewModel: PlayerViewModel)
}

protocol PlayerViewModel {
    
    var trackInfo: BehaviorRelay<TrackInfo?> { get }
    var timeInfo: BehaviorRelay<TrackTimeInfo?> { get }
    var playbackInfo: BehaviorRelay<PlaybackInfo> { get }
    var isTimeChangingInProgress: Bool { get }
    
    func pause()
    func play()
    func restart()
    func switchToNextTrack()
    func switchToPrevTrack()
    func seek(to position: PlaybackPosition)
    
    func collapsePlayer()
}

class PlayerViewModelImplementation: PlayerViewModel {
    
    // MARK: - Properties
    
    var trackInfo: BehaviorRelay<TrackInfo?> {
        return dropboxPlayer.trackInfo
    }
    var timeInfo: BehaviorRelay<TrackTimeInfo?> {
        return dropboxPlayer.timeInfo
    }
    var playbackInfo: BehaviorRelay<PlaybackInfo> {
        return dropboxPlayer.playbackInfo
    }
    
    weak var delegate: PlayerViewModelDelegate?

    var isTimeChangingInProgress: Bool {
        return dropboxPlayer.isTimeChangingInProgress
    }
    private let dropboxPlayer: DropboxPlayer
    
    // MARK: - Init
    
    init(with dropboxPlayer: DropboxPlayer) {
        self.dropboxPlayer = dropboxPlayer
    }
    
    // MARK: - Public methods
    
    func restart() {
        dropboxPlayer.restart()
    }
    
    func seek(to position: PlaybackPosition) {
        dropboxPlayer.seek(to: position)
    }
    
    func switchToPrevTrack() {
        dropboxPlayer.switchToPrevTrack()
    }
    
    func switchToNextTrack() {
        dropboxPlayer.switchToNextTrack()
    }
    
    func pause() {
        dropboxPlayer.pause()
    }
    
    func play() {
        dropboxPlayer.play()
    }
    
    func collapsePlayer() {
        delegate?.playerViewModelDidRequestToCollapse(self)
    }
}
