//
//  PlayerTransitioningDelegate.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import UIKit

class PlayerTransitioningDelegate: NSObject {

    private let animationController = PlayerTransitionAnimator()
    private let transitionController: PlayerDismissTransitionController

    init(transitionController: PlayerDismissTransitionController) {
        self.transitionController = transitionController
        super.init()
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension PlayerTransitioningDelegate: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        animationController.transitionType = .presenting
        return animationController
    }

    func animationController(
        forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        animationController.transitionType = .dismissing
        return animationController
    }

    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {

        return transitionController.hasStarted ? transitionController : nil
    }
}
