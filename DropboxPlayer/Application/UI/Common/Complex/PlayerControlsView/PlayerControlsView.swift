//
//  PlayerControlsView.swift
//  DropboxPlayer
//
//  Created by Oleg on 25/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

enum PlayerControlsViewAction {
    case rewind, pause, play, fastForward, retry
}

@IBDesignable
class PlayerControlsView: UIView {

    typealias PlayerControlsActionHandler = (PlayerControlsViewAction) -> Void
    
    // MARK: - Properties
    
    private let toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        return toolbar
    }()
    
    private lazy var previousTrackItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .rewind,
                                   target: self,
                                   action: #selector(previousTrackButtonTapped))
        item.isEnabled = isPreviousButtonEnabled
        return item
    }()
    
    private lazy var nextTrackItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .fastForward,
                                   target: self,
                                   action: #selector(nextTrackButtonTapped))
        item.isEnabled = isNextButtonEnabled
        return item
    }()
    
    private lazy var retryItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .refresh,
                                   target: self,
                                   action: #selector(retryButtonTapped))
        return item
    }()
    
    var isNextButtonEnabled: Bool = false {
        didSet {
            nextTrackItem.isEnabled = isNextButtonEnabled
        }
    }
    
    var isPreviousButtonEnabled: Bool = false {
        didSet {
            previousTrackItem.isEnabled = isPreviousButtonEnabled
        }
    }
    
    var isPlayButtonEnabled: Bool = false {
        didSet {
            updateToolbarItems()
        }
    }
    
    var isPlaying: Bool = false {
        didSet {
            updateToolbarItems()
        }
    }
    
    var isRetryButtonEnabled: Bool = false {
        didSet {
            updateToolbarItems()
        }
    }
    
    var actionsHandler: PlayerControlsActionHandler?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    // MARK: - Private
    
    private func setupUI() {
        addSubview(toolbar)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor)])
        updateToolbarItems()
    }
    
    private func updateToolbarItems(animated: Bool = false) {
        let items = [previousTrackItem,
                     UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                     target: nil,
                                     action: nil),
                     makeCenterButton(),
                     UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                     target: nil,
                                     action: nil),
                     nextTrackItem]
        toolbar.setItems(items, animated: animated)
    }
    
    private func makeCenterButton() -> UIBarButtonItem {
        guard !isRetryButtonEnabled else {
            return retryItem
        }
        let item = UIBarButtonItem(barButtonSystemItem: isPlaying ? .pause : .play,
                                   target: self,
                                   action: #selector(playPauseButtonTapped))
        item.isEnabled = isPlayButtonEnabled
        return item
    }
    
    // MARK: - Actions
    
    @objc private func previousTrackButtonTapped() {
        actionsHandler?(.rewind)
    }
    
    @objc private func nextTrackButtonTapped() {
        actionsHandler?(.fastForward)
    }
    
    @objc private func playPauseButtonTapped() {
        actionsHandler?(isPlaying ? .pause : .play)
    }
    
    @objc private func retryButtonTapped() {
        actionsHandler?(.retry)
    }
}
