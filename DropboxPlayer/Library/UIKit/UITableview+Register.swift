//
//  UITableview+Register.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

extension UITableViewCell {
    
    static var reuseIndntifier: String {
        return String(describing: self)
    }
    
    private static var cellNib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    class func registerNib(in table: UITableView) {
        
        table.register(cellNib, forCellReuseIdentifier: reuseIndntifier)
    }
    
    class func register(in table: UITableView) {
        table.register(self, forCellReuseIdentifier: reuseIndntifier)
    }
}
