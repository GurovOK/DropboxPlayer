//
//  String+Localization.swift
//  DropboxPlayer
//
//  Created by Oleg on 14/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

extension String {
    
    func localized(withComment comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
