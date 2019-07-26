//
//  NavigationObserver.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import UIKit

protocol NavigationPopObserver: class {
    
    func navigationObserver(_ observer: NavigationObserver,
                            didObserveTargetViewControllerPop viewController: UIViewController)
}

private struct NavigationPopObserverWrapper {
    
    weak var observer: NavigationPopObserver?
    weak var observedController: UIViewController?
}

class NavigationObserver: NSObject {
    
    private let navigationController: UINavigationController
    private var observers: [NavigationPopObserverWrapper] = []
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        navigationController.delegate = self
    }
    
    func addObserver(_ observer: NavigationPopObserver,
                     forPopOf targetViewController: UIViewController) {
        observers.append(NavigationPopObserverWrapper(observer: observer,
                                                      observedController: targetViewController))
    }
}

extension NavigationObserver: UINavigationControllerDelegate {
  
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        guard let poppedViewController = navigationController.poppedViewController else {
            return
        }
        if let (index, observer) = observers.enumerated().first(where: {
            $1.observedController == poppedViewController
        }) {
            
            observer.observer?.navigationObserver(self,
                                                  didObserveTargetViewControllerPop: poppedViewController)
            observers.remove(at: index)
        }
    }
}
