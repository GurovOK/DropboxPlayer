//
//  UIColor+AppColors.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

extension UIColor {
    
    // MARK: - Common
    
    class func color(fromRed red: Int,
                     green: Int,
                     blue: Int,
                     alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: CGFloat(red) / 255,
                       green: CGFloat(green) / 255,
                       blue: CGFloat(blue) / 255,
                       alpha: alpha)
    }
    
    // MARK: - Colors
    
    static let primary = color(fromRed: 89, green: 149, blue: 236)
    static let textPrimary = color(fromRed: 0, green: 0, blue: 34)
}

