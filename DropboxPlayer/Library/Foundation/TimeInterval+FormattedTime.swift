//
//  TimeInterval+FormattedTime.swift
//  DropboxPlayer
//
//  Created by Oleg on 19/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

extension TimeInterval {
    
    func formattedTimeString() -> String {
        guard !self.isNaN, !self.isInfinite else {
            return ""
        }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: self) ?? ""
    }
}
