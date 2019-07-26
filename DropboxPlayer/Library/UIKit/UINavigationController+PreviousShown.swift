//
//  UINavigationController+PreviousShown.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

extension UINavigationController {
    var poppedViewController: UIViewController? {
        guard let fromViewController = transitionCoordinator?.viewController(forKey: .from),
            !viewControllers.contains(fromViewController) else {
                return nil
        }
        return fromViewController
    }
}
