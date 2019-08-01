//
//  PlayerViewController.swift
//  DropboxPlayer
//
//  Created by Oleg on 23/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift
import MediaPlayer

protocol PlayerViewControllerDelegate: class {
    
    func playerViewControllerDidReqiestToInteractiveDismiss(_ viewController: PlayerViewController)
    func playerViewControllerDidFinishInteractiveDismiss(_ viewController: PlayerViewController)
}

class PlayerViewController: UIViewController {

    private struct ObserverKey {
        static let status = "status"
        static let currentItem = "currentItem"
    }
    
    private struct Constants {
        static let timeObserverInterval: TimeInterval = 1
        static let dismissPercentThreshold: CGFloat = 0.5
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var bufferingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var currentTimeLabel: UILabel!
    @IBOutlet private weak var timeLeftLabel: UILabel!
    @IBOutlet private weak var albumNameLabel: UILabel!
    @IBOutlet private weak var trackNameLabel: UILabel!
    @IBOutlet private weak var timelineView: UISlider!
    @IBOutlet private weak var trackPositionLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel! {
        didSet {
            errorLabel.text = "Ошибка воспроизведения".localized()
        }
    }
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var playerControlsView: PlayerControlsView!
    
    // MARK: - Properties
    
    weak var delegate: PlayerViewControllerDelegate?
    
    private let viewModel: PlayerViewModel
    private let disposeBag = DisposeBag()
    private var timeObserver: Any?
    private var timedMetadataObserver: NSKeyValueObservation?
    private var playbackFinishedObserver: NSObjectProtocol?
    private var isTimeEditing: Bool {
        return timelineView.isTracking
    }
    private var lastTimeInfo: TrackTimeInfo?
    private var artworkChangeWorkItem: DispatchWorkItem?
    private let transitionController: PlayerTransitionController?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Init
    
    init(viewModel: PlayerViewModel,
         transitionController: PlayerTransitionController?) {
        self.viewModel = viewModel
        self.transitionController = transitionController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerControlsView.actionsHandler = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .play:
                self.playButtonTapped()
            case .pause:
                self.pauseButtonTapped()
            case .fastForward:
                self.fastForwardButtonTapped()
            case .rewind:
                self.rewindButtonTapped()
            case .retry:
                self.viewModel.restart()
            }
        }
        bindToViewModel()
        setupPanContentRecognizer()
    }
    
    // MARK: - Private methods
    
    private func bindToViewModel() {
        viewModel
            .trackInfo
            .subscribe(onNext: { [weak self] trackInfo in
                self?.handle(trackInfo)
            }).disposed(by: disposeBag)
        viewModel
            .timeInfo
            .subscribe(onNext: { [weak self] timeInfo in
                self?.handle(timeInfo)
            }).disposed(by: disposeBag)
        viewModel
            .playbackInfo
            .subscribe(onNext: { [weak self] playbackInfo in
                self?.handle(playbackInfo)
            }).disposed(by: disposeBag)
    }
    
    private func handle(_ playbackInfo: PlaybackInfo) {
        setLoadingIndicatorVisible(playbackInfo.isPreparing)
        
        errorView.isHidden = !playbackInfo.isPlaybackFailed
        timelineView.isEnabled = playbackInfo.canEditPlaybackPosition
        
        playerControlsView.isPlaying = playbackInfo.isPlaying
        playerControlsView.isPlayButtonEnabled = playbackInfo.playbackAvailable
        playerControlsView.isRetryButtonEnabled = playbackInfo.isPlaybackFailed
        playerControlsView.isNextButtonEnabled = playbackInfo.nextTrackAvailable
        playerControlsView.isPreviousButtonEnabled = playbackInfo.previousTrackAvailable
    }
    
    private func updatePlayButton(with state: PlaybackState) {
        switch state {
        case .playing:
            playerControlsView.isPlaying = true
        default:
            playerControlsView.isPlaying = false
        }
    }
    
    private func handle(_ trackInfo: TrackInfo?) {
        title = trackInfo?.playlistName
        albumNameLabel.text = trackInfo?.albumName
        trackNameLabel.text = trackInfo?.trackName
        trackPositionLabel.text = trackInfo?.positionInfoString
        albumNameLabel.isHidden = trackInfo?.albumName == nil
        trackPositionLabel.isHidden = trackInfo?.positionInfoString == nil
        updateArtwork(with: trackInfo)
    }
    
    private func updateArtwork(with trackInfo: TrackInfo?) {
        artworkChangeWorkItem?.cancel()
        artworkChangeWorkItem = nil
        if let data = trackInfo?.artworkData {
            let workItem = DispatchWorkItem(block: {
                let image = UIImage(data: data)
                DispatchQueue.main.async { [weak self] in
                    self?.artworkImageView.image = image
                    self?.artworkChangeWorkItem = nil
                }
            })
            artworkChangeWorkItem = workItem
            DispatchQueue.global().async(execute: workItem)
        } else {
            artworkImageView.image = nil
        }
    }
    
    private func handle(_ timeInfo: TrackTimeInfo?) {
        updatePlaybackTime(with: timeInfo)
    }
    
    private func resetCurrentPlaybackItem() {
        playerControlsView.isPlayButtonEnabled = false
        playerControlsView.isNextButtonEnabled = false
        resetCurrentTime()
    }
    
    private func resetCurrentTime() {
        currentTimeLabel.text = nil
        timeLeftLabel.text = nil
        timelineView.value = 0
    }
    
    private func setLoadingIndicatorVisible(_ visible: Bool) {
        if visible {
            bufferingIndicator.startAnimating()
        } else {
            bufferingIndicator.stopAnimating()
        }
    }
    
    private func updatePlaybackTime(with timeInfo: TrackTimeInfo?) {
        lastTimeInfo = timeInfo
        guard !viewModel.isTimeChangingInProgress, !isTimeEditing else {
            return
        }
        updateTimeInfoLabels(withCurrentTime: timeInfo?.currentTime,
                             duration: timeInfo?.duration)
        updateTimelineValue(withCurrentTime: timeInfo?.currentTime,
                            duration: timeInfo?.duration)
    }
    
    private func updateTimeInfoLabels(withCurrentTime time: TimeInterval?,
                                      duration: TimeInterval?) {
        var currentTime: String?
        var timeLeft: String?
        if let time = time,
            let duration = duration,
            duration > 0 {
            currentTime = "\(time.formattedTimeString())"
            timeLeft = "-\((duration - time).formattedTimeString())"
        }
        currentTimeLabel.text = currentTime
        timeLeftLabel.text = timeLeft
    }
    
    private func updateTimelineValue(withCurrentTime time: TimeInterval?,
                                     duration: TimeInterval?) {
        var timelineValue: Float = 0
        if let time = time,
            let duration = duration,
            duration > 0 {
            let percent = time / duration
            timelineValue = Float(percent)
        }
        timelineView.value = timelineValue
    }
    
    private func setupPanContentRecognizer() {
        let panRecognizer = UIPanGestureRecognizer(target: self,
                                                   action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panRecognizer)
    }
    
    // MARK: - Actions

    @objc private func pauseButtonTapped() {
        viewModel.pause()
    }

    @objc private func playButtonTapped() {
        viewModel.play()
    }

    @objc private func fastForwardButtonTapped() {
        viewModel.switchToNextTrack()
    }

    @objc private func rewindButtonTapped() {
        viewModel.switchToPrevTrack()
    }
    
    @IBAction func timelineValueChanged(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        switch touch.phase {
        case .moved:
            guard let duration = lastTimeInfo?.duration else {
                return
            }
            let time = duration * TimeInterval(timelineView.value)
            updateTimeInfoLabels(withCurrentTime: time,
                                 duration: duration)
        case .ended:
            viewModel.seek(to: Double(timelineView.value))
        case .began, .cancelled, .stationary:
            break
        @unknown default:
            break
        }
    }
    
    @IBAction private func collapseButtonTapped() {
        viewModel.collapsePlayer()
    }
}

extension PlayerViewController {
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {

        guard let transitionController = self.transitionController,
            let delegate = self.delegate else { return }
        
        let translation = recognizer.translation(in: view)
        let contentHeight = view.bounds.height
        let verticalMovement = translation.y / contentHeight
        let downwardMovement: CGFloat = max(verticalMovement, 0)
        let downwardMovementPercent: CGFloat = min(downwardMovement, 1)
        switch recognizer.state {
        case .began:
            transitionController.hasStarted = true
            delegate.playerViewControllerDidReqiestToInteractiveDismiss(self)
        case .changed:
            if transitionController.hasStarted {
                transitionController.shouldFinish = downwardMovementPercent > Constants.dismissPercentThreshold
                transitionController.update(downwardMovementPercent)
            }
        case .cancelled, .failed:
            transitionController.hasStarted = false
            transitionController.cancel()
        case .ended:
            let velocity = recognizer.velocity(in: view).y
            transitionController.hasStarted = false
            if velocity > 2000 || transitionController.shouldFinish {
                transitionController.finish()
                delegate.playerViewControllerDidFinishInteractiveDismiss(self)
            } else {
                transitionController.cancel()
            }
        case .possible:
            break
        @unknown default:
            break
        }
    }
}
