//
//  PlayerCoordinator.swift
//  DropboxPlayer
//
//  Created by Oleg on 12/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

class PlayerCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    var childCoordinators: [BaseCoordinator] = []
    var onDidFinish: (() -> Void)?
    
    private lazy var transitionController = PlayerDismissTransitionController()
    private lazy var transitionDelegate = PlayerTransitioningDelegate(transitionController: transitionController)
    private let presenter: UIViewController
    private let appDependency: AppDependencies
    
    // MARK: - Init
    
    init(presenter: UIViewController,
         appDependency: AppDependencies) {
        self.presenter = presenter
        self.appDependency = appDependency
    }
    
    // MARK: - Public methods
    
    func start() {
        let viewModel = PlayerViewModelImplementation(with: appDependency.playbackController.dropboxPlayer)
        viewModel.delegate = self
        let viewController = PlayerViewController(viewModel: viewModel,
                                                  transitionController: transitionController)
        viewController.delegate = self
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = transitionDelegate
        viewController.modalPresentationCapturesStatusBarAppearance = true
        presenter.present(viewController, animated: true, completion: nil)
    }
}

// MARK: - PlayerViewModelDelegate
extension PlayerCoordinator: PlayerViewModelDelegate {
    
    func playerViewModelDidRequestToCollapse(_ viewModel: PlayerViewModel) {
        presenter.dismiss(animated: true, completion: nil)
        onDidFinish?()
    }
}

// MARK: - PlayerViewControllerDelegate
extension PlayerCoordinator: PlayerViewControllerDelegate {
    
    func playerViewControllerDidReqiestToInteractiveDismiss(_ viewController: PlayerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
