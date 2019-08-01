//
//  LibraryCoordinator.swift
//  DropboxPlayer
//
//  Created by Oleg on 14/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

protocol LibraryCoordinatorDelegate: class {
    
    func didRequestToSelectPlayerTab()
}

class LibraryCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    weak var delegate: LibraryCoordinatorDelegate?
    var childCoordinators: [BaseCoordinator] = []
    var onDidFinish: (() -> Void)?
    
    private let navigationController: UINavigationController
    private let appDependency: AppDependencies
    private let navigationObserver: NavigationObserver
    private var transitionController: PlayerTransitionController?
    
    // MARK: - Init
    
    init(navigationController: UINavigationController,
         navigationObserver: NavigationObserver,
         appDependency: AppDependencies) {
        
        self.navigationController = navigationController
        self.navigationObserver = navigationObserver
        self.appDependency = appDependency
    }
    
    // MARK: - Public methods
    
    func start() {
        let playerViewModel = MiniPlayerViewModelImplementation(with: appDependency.playbackController.dropboxPlayer)
        playerViewModel.delegate = self
        let viewModel = LibraryViewModelImplementation(title: "Библиотека".localized(),
                                                       dependencies: appDependency,
                                                       miniPlayerViewModel: playerViewModel)
        viewModel.delegate = self
        let viewController = LibraryViewController(with: viewModel)
        viewController.delegate = self
        viewController.tabBarItem.image = #imageLiteral(resourceName: "playlistIcon.pdf")
        viewController.navigationItem.rightBarButtonItems = viewController.makeRightBarButtonItems()
        navigationController.setViewControllers([viewController], animated: false)
    }
    
    // MARK: - Private methods
    
    private func startEditPlaylistFlow(with playlist: Playlist) {
        let coordinator = PlaylistEditingCoordinator(presentationController: navigationController,
                                                     appDependency: appDependency,
                                                     playlist: playlist)
        addChild(coordinator: coordinator)
        coordinator.start()
    }

    private func openFullscreenPlayer(
        transitionController: PlayerTransitionController = PlayerTransitionController()) {
        let coordinator = PlayerCoordinator(presenter: navigationController,
                                            appDependency: appDependency,
                                            transitionController: transitionController)
        addChild(coordinator: coordinator)
        coordinator.start()
    }
}

// MARK: - LibraryViewModelDelegate
extension LibraryCoordinator: LibraryViewModelDelegate {
    
    func didSelectPlaylist() {
        openFullscreenPlayer()
    }
    
    func didRequestToEdit(playlist: Playlist) {
        startEditPlaylistFlow(with: playlist)
    }
}

// MARK: - MiniPlayerViewModelDelegate
extension LibraryCoordinator: MiniPlayerViewModelDelegate {

    func miniPlayerViewModelDidRequestToOpenFullscreen(_ viewModel: MiniPlayerViewModel) {
        openFullscreenPlayer()
    }
}

// MARK: - LibraryViewControllerDelegate
extension LibraryCoordinator: LibraryViewControllerDelegate {
    
    func libraryViewController(_ viewController: LibraryViewController,
                               didRequestToOpenPlayerWithTransitionController controller: PlayerTransitionController) {
        openFullscreenPlayer(transitionController: controller)
    }
}

