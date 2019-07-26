//
//  UIKit+FromNib.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

extension UIView {
 
    class func fromNib() -> Self {
        return fromNib(type: self, owner: nil)
    }
    
    class func contentViewFromNib(withOwner owner: Any) -> UIView {
        return fromNib(type: UIView.self, owner: owner)
    }
    
    private class func fromNib<T>(type: T.Type, owner: Any? = nil) -> T {
        guard let nibName = className() else {
            preconditionFailure()
        }
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let view = nib.instantiate(withOwner: owner, options: nil).first as? T else {
            preconditionFailure()
        }
        return view
    }
    
    private class func className() -> String? {
        let className = "\(self)"
        let components = className.split(separator: ".").map { return String($0) }
        return components.last
    }
}
