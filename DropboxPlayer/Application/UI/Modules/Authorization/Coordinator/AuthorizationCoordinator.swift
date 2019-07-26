//
//  AuthorizationCoordinator.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

protocol AuthorizationCoordinatorDelegate: class {
    func authorizationCoordinatorDidAuthorize(_ coordinator: AuthorizationCoordinator)
}

class AuthorizationCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    weak var delegate: AuthorizationCoordinatorDelegate?
    var childCoordinators: [BaseCoordinator] = []
    var onDidFinish: (() -> Void)?
    
    private let navigationController: UINavigationController
    private let appDependency: AppDependencies
    
    // MARK: - Init
    
    init(navigationController: UINavigationController,
         appDependency: AppDependencies) {
        self.navigationController = navigationController
        self.appDependency = appDependency
    }
    
    // MARK: - Public methods
    
    func start() {
        let authorizationHelper = DropboxAuthorizationHelper(dependencies: appDependency,
                                                             target: navigationController)
        let viewModel = AuthorizationViewModelImplementation(authorizationHelper: authorizationHelper)
        viewModel.delegate = self
        let viewController = AuthorizationViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
    }
}

// MARK: - AuthorizationViewModelDelegate
extension AuthorizationCoordinator: AuthorizationViewModelDelegate {
    
    func authorizationViewModelDidAuthorize(_ viewModel: AuthorizationViewModel) {
        delegate?.authorizationCoordinatorDidAuthorize(self)
    }
}
