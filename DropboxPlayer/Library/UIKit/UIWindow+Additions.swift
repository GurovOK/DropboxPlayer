//
//  UIWindow+Additions.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

extension UIWindow {
    
    func replace(rootController: UIViewController,
                 animated: Bool,
                 duration: TimeInterval = 0.3) {
        let replaceBlock = {
            self.rootViewController = rootController
        }
        if animated {
            UIView.transition(with: self,
                              duration: duration,
                              options: .transitionFlipFromLeft,
                              animations: {
                                replaceBlock()
            }, completion: nil)
        } else {
            replaceBlock()
        }
    }
}
