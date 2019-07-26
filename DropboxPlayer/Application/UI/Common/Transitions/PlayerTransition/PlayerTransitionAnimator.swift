//
//  PlayerTransitionAnimator.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import UIKit

class PlayerTransitionAnimator: NSObject {

    enum TransitionType {
        case presenting, dismissing
    }

    var transitionType: TransitionType = .presenting
    private let duration: TimeInterval
    private let blurStyle: UIBlurEffect.Style
    private lazy var effect = UIBlurEffect(style: blurStyle)
    private lazy var blurView: UIVisualEffectView = UIVisualEffectView(effect: effect)

    init(duration: TimeInterval = 0.3,
         blurStyle: UIBlurEffect.Style = .dark) {

        self.duration = duration
        self.blurStyle = blurStyle
    }
}

extension PlayerTransitionAnimator: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else {
                return
        }
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        let startFrame: CGRect
        let finalFrame: CGRect
        switch transitionType {
        case .presenting:
            let toRect = transitionContext.finalFrame(for: fromVC)
            blurView.frame = toRect
            blurView.effect = nil
            containerView.addSubview(blurView)
            containerView.addSubview(toVC.view)
            finalFrame = toRect
            startFrame = CGRect(origin: CGPoint(x: 0, y: toRect.height), size: toRect.size)
            toVC.view.frame = startFrame
        case .dismissing:
            let finalSize = fromVC.view.bounds.size
            finalFrame = CGRect(origin: CGPoint(x: 0, y: fromVC.view.bounds.height), size: finalSize)
            startFrame = toVC.view.bounds
            fromVC.view.frame = startFrame
        }
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration,
                       delay: transitionContext.isInteractive ? duration : 0,
                       options: [.curveLinear],
                       animations: {
                        switch self.transitionType {
                        case .presenting:
                            self.blurView.effect = self.effect
                            toVC.view.frame = finalFrame
                        case .dismissing:
                            self.blurView.effect = nil
                            fromVC.view.frame = finalFrame
                        }
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
