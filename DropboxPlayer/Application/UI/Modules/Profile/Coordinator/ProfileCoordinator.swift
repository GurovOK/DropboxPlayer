//
//  ProfileCoordinator.swift
//  DropboxPlayer
//
//  Created by Oleg on 18/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

protocol ProfileCoordinatorDelegate: class {
    
    func profileCoordinatorDidLogout(_ coordinator: ProfileCoordinator)
}

class ProfileCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    weak var delegate: ProfileCoordinatorDelegate?
    var childCoordinators: [BaseCoordinator] = []
    var onDidFinish: (() -> Void)?
    
    private let navigationController: UINavigationController
    private let navigationObserver: NavigationObserver
    private let appDependency: AppDependencies
    
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
        
        let viewModel = ProfileViewModelImplementation(dependencies: appDependency)
        viewModel.delegate = self
        let viewController = ProfileViewController(viewModel: viewModel)
        viewController.tabBarItem.image = #imageLiteral(resourceName: "profileIcon.pdf")
        navigationController.setViewControllers([viewController], animated: false)
    }
}

// MARK: - ProfileViewModelDelegate
extension ProfileCoordinator: ProfileViewModelDelegate {
    
    func profileViewModelDidLogout(_ viewModel: ProfileViewModel) {
        delegate?.profileCoordinatorDidLogout(self)
    }
}
