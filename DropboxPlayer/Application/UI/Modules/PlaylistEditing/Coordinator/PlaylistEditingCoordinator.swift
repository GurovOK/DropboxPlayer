//
//  PlaylistEditingCoordinator.swift
//  DropboxPlayer
//
//  Created by Oleg on 15/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

class PlaylistEditingCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    var childCoordinators: [BaseCoordinator] = []
    var onDidFinish: (() -> Void)?
    
    private let presentationController: UIViewController
    private let appDependency: AppDependencies
    private let playlist: Playlist
    private var onDidSelectFiles: (([AudioFile]) -> Void)?
    
    // MARK: - Init
    
    init(presentationController: UIViewController,
         appDependency: AppDependencies,
         playlist: Playlist) {
        
        self.presentationController = presentationController
        self.appDependency = appDependency
        self.playlist = playlist
    }
    
    // MARK: - Public methods
    
    func start() {
        let viewModel = PlaylistEditingViewModelImplementation(with: playlist,
                                                            dependencies: appDependency)
        viewModel.delegate = self
        let editPlaylistController = PlaylistEditingViewController(viewModel: viewModel)
        editPlaylistController.navigationItem.rightBarButtonItems = editPlaylistController.makeRightBarButtonItems()
        editPlaylistController.navigationItem.leftBarButtonItems = editPlaylistController.makeLeftBarButtonItems()
        let navigationController = UINavigationController(rootViewController: editPlaylistController)
        onDidSelectFiles = { [weak viewModel] files in
            viewModel?.appendFiles(files)
        }
        presentationController.present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - EditPlaylistViewModelDelegate
extension PlaylistEditingCoordinator: PlaylistEditingViewModelDelegate {
    
    private func close() {
        presentationController.dismiss(animated: true) { [weak self] in
            self?.onDidFinish?()
        }
    }
    
    func didSavePlaylist() {
        close()
    }
    
    func didRequestToClose() {
        close()
    }
    
    func didRequestToSelectFiles() {
        guard let topController = presentationController.presentedViewController else { return }
        let browserCoordinator = FileBrowserCoordinator(presentationController: topController,
                                                        appDependency: appDependency)
        browserCoordinator.delegate = self
        addChild(coordinator: browserCoordinator)
        browserCoordinator.start()
    }
}

// MARK: - EditPlaylistViewModelDelegate
extension PlaylistEditingCoordinator: FileBrowserCoordinatorDelegate {
    
    func didSelectFiles(_ files: [AudioFile]) {
        onDidSelectFiles?(files)
    }
}
