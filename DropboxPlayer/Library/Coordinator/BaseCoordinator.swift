//
//  BaseCoordinator.swift
//  FoodChecker
//
//  Created by Oleg on 13/02/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import UIKit

protocol BaseCoordinator: NavigationPopObserver {
    
    var childCoordinators: [BaseCoordinator] { get set }
    var onDidFinish: (() -> Void)? { get set }
    
    func start()
    func addChild(coordinator: BaseCoordinator)
    func removeChild(coordinator: BaseCoordinator)
}

extension BaseCoordinator {
    
    func addChild(coordinator: BaseCoordinator) {
        
        guard !childCoordinators.contains(where: { $0 === coordinator }) else { return }
        childCoordinators.append(coordinator)
        coordinator.onDidFinish = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else { return }
            self.removeChild(coordinator: coordinator)
        }
    }
    
    func removeChild(coordinator: BaseCoordinator) {
        
        guard let index = childCoordinators.firstIndex(where: { $0 === coordinator }) else { return }
        childCoordinators.remove(at: index)
    }
}

// MARK: - NavigationPopObserver
extension BaseCoordinator {
    
    func navigationObserver(_ observer: NavigationObserver,
                            didObserveTargetViewControllerPop viewController: UIViewController) {
        
        onDidFinish?()
    }
}
