//
//  Playlist.swift
//  DropboxPlayer
//
//  Created by Oleg on 10/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

struct Playlist {
    
    let id: String
    var name: String
    var items: [PlaylistItem]
    let accountId: String
    
    init(id: String = UUID().uuidString,
         name: String,
         items: [PlaylistItem],
         accountId: String) {
        
        self.id = id
        self.name = name
        self.items = items
        self.accountId = accountId
    }
}

extension Playlist {
    
    var currentTrack: PlaylistItem? {
        return items.first(where: {
            if case .playback(_) = $0.state {
                return true
            } else {
                return false
            }
        }) ?? items.first
    }
    
    var nextTrack: PlaylistItem? {
        
        guard let currentTrack = currentTrack,
            let currentIndex = items.firstIndex(of: currentTrack) else {
                return nil
        }
        let nextIndex = items.index(after: currentIndex)
        if nextIndex < items.count {
            return items[nextIndex]
        }
        return nil
    }
    
    var prevTrack: PlaylistItem? {
        
        guard let currentTrack = currentTrack,
            let currentIndex = items.firstIndex(of: currentTrack) else {
                return nil
        }
        let prevIndex = items.index(before: currentIndex)
        if prevIndex >= 0, prevIndex < items.count {
            return items[prevIndex]
        }
        return nil
    }
}

extension Playlist: Equatable {
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}
