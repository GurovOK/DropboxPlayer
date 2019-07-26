//
//  MainCoordinator.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

enum MainControllerTab {
    case library
    case player
    case profile
}

typealias MainControllerItem = (tab: MainControllerTab, controller: UIViewController)

class MainCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    var childCoordinators: [BaseCoordinator] = []
    var onDidFinish: (() -> Void)?
    
    private let appDependency: AppDependencies
    private let disposeBag = DisposeBag()
    private let window: UIWindow
    
    // MARK: - Init
    
    init(window: UIWindow,
         appDependency: AppDependencies) {
        self.window = window
        self.appDependency = appDependency
    }
    
    // MARK: - Public methods
    
    func start() {
        appDependency.dropboxService.delegate = self
        if !appDependency.dropboxService.isAuthorized {
            startAuth()
        } else {
            startHome()
        }
        window.makeKeyAndVisible()
    }
    
    // MARK: - Private methods
    
    private func startAuth(animated: Bool = false) {
        let navigationController = UINavigationController()
        let coordinator = AuthorizationCoordinator(navigationController: navigationController,
                                                   appDependency: appDependency)
        coordinator.delegate = self
        coordinator.addChild(coordinator: coordinator)
        coordinator.start()
        window.replace(rootController: navigationController, animated: animated)
    }
    
    private func startHome(animated: Bool = false) {
        let mainController = MainViewController()
        mainController.items = [
            makeLibraryItem(),
            makeProfileItem()
        ]
        window.replace(rootController: mainController, animated: animated)
    }
    
    private func makeLibraryItem() -> MainControllerItem {
        let navigationController = UINavigationController()
        let navigationObserver = NavigationObserver(navigationController: navigationController)
        let coordinator = LibraryCoordinator(
            navigationController: navigationController,
            navigationObserver: navigationObserver,
            appDependency: appDependency)
        coordinator.delegate = self
        addChild(coordinator: coordinator)
        coordinator.start()
        return (.library, navigationController)
    }
    
    private func makeProfileItem() -> MainControllerItem {
        let navigationController = UINavigationController()
        let navigationObserver = NavigationObserver(navigationController: navigationController)
        let coordinator = ProfileCoordinator(
            navigationController: navigationController,
            navigationObserver: navigationObserver,
            appDependency: appDependency)
        coordinator.delegate = self
        addChild(coordinator: coordinator)
        coordinator.start()
        return (.profile, navigationController)
    }
    
    private func userDidLogout() {
        appDependency.playbackController.clearPlayback()
        appDependency.userInfoProvider.clearCachedUserInfo()
        startAuth(animated: true)
    }
}

// MARK: - AuthorizationCoordinatorDelegate
extension MainCoordinator: AuthorizationCoordinatorDelegate {
    
    func authorizationCoordinatorDidAuthorize(_ coordinator: AuthorizationCoordinator) {
        startHome(animated: true)
    }
}

// MARK: - LibraryCoordinatorDelegate
extension MainCoordinator: LibraryCoordinatorDelegate {
    
    func didRequestToSelectPlayerTab() {
        guard let tabBarController = window.rootViewController as? MainViewController else {
            return
        }
        tabBarController.select(tab: .player)
    }
}

// MARK: - ProfileCoordinatorDelegate
extension MainCoordinator: ProfileCoordinatorDelegate {
    
    func profileCoordinatorDidLogout(_ coordinator: ProfileCoordinator) {
        userDidLogout()
    }
}

// MARK: - DropboxServiceDelegate
extension MainCoordinator: DropboxServiceDelegate {
    
    func dropboxServiceDidHandleUnauthorizeError(_ service: DropboxService) {
        userDidLogout()
    }
}
