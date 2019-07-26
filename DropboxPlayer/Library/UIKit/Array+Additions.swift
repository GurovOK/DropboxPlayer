//
//  Array+Additions.swift
//  DropboxPlayer
//
//  Created by Oleg on 02/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

extension Array {
    
    func item(at index: Int) -> Element? {
        guard index >= 0, index < self.count else { return nil }
        return self[index]
    }
}
