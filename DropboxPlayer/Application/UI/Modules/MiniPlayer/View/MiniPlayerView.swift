//
//  MiniPlayerView.swift
//  DropboxPlayer
//
//  Created by Oleg on 24/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift

class MiniPlayerView: UIView {

    // MARK: - Outlets
    
    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var trackNameLabel: UILabel!
    @IBOutlet private weak var trackPositionLabel: UILabel!
    @IBOutlet private weak var controlsView: PlayerControlsView! {
        didSet {
            configureControlsView()
        }
    }
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var artworkChangeWorkItem: DispatchWorkItem?
    private var viewModel: MiniPlayerViewModel?
    private let disposeBag = DisposeBag()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Public methods

    private func setup() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        addGestureRecognizer(tapRecognizer)
    }

    func configure(with viewModel: MiniPlayerViewModel) {
        viewModel
            .trackInfo
            .subscribe(onNext: { [weak self] trackInfo in
                self?.handle(trackInfo: trackInfo)
            }).disposed(by: disposeBag)
        viewModel
            .playbackInfo
            .subscribe(onNext: { [weak self] playbackInfo in
                self?.handle(playbackInfo)
            }).disposed(by: disposeBag)
        self.viewModel = viewModel
    }
    
    // MARK: - Private methods
    
    private func handle(_ playbackInfo: PlaybackInfo) {
        if playbackInfo.isPreparing {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        controlsView.isPlaying = playbackInfo.isPlaying
        controlsView.isRetryButtonEnabled = playbackInfo.isPlaybackFailed
        controlsView.isPlayButtonEnabled = playbackInfo.playbackAvailable
        controlsView.isNextButtonEnabled = playbackInfo.nextTrackAvailable
        controlsView.isPreviousButtonEnabled = playbackInfo.previousTrackAvailable
    }

    private func handle(trackInfo: TrackInfo?) {
        trackNameLabel.text = trackInfo?.trackName
        trackNameLabel.isHidden = trackInfo?.trackName == nil
        trackPositionLabel.text = trackInfo?.positionInfoString
        trackPositionLabel.isHidden = trackInfo?.positionInfoString == nil
        updateArtwork(with: trackInfo)
    }
    
    private func configureControlsView() {
        controlsView.actionsHandler = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .play:
                self.viewModel?.play()
            case .pause:
                self.viewModel?.pause()
            case .fastForward:
                self.viewModel?.switchToNextTrack()
            case .rewind:
                self.viewModel?.switchToPrevTrack()
            case .retry:
                self.viewModel?.restart()
            }
        }
    }
    
    private func updateArtwork(with trackInfo: TrackInfo?) {
        artworkChangeWorkItem?.cancel()
        artworkChangeWorkItem = nil
        if let data = trackInfo?.artworkData {
            let workItem = DispatchWorkItem(block: {
                let image = UIImage(data: data)
                DispatchQueue.main.async { [weak self] in
                    self?.artworkImageView.image = image
                    self?.artworkImageView.isHidden = false
                    self?.artworkChangeWorkItem = nil
                }
            })
            artworkChangeWorkItem = workItem
            DispatchQueue.global().async(execute: workItem)
        } else {
            artworkImageView.image = nil
            artworkImageView.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func backgroundTapped() {
        viewModel?.openFullscreenPlayer()
    }
}
