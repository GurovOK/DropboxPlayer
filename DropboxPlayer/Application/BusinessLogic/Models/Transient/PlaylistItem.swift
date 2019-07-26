//
//  PlaylistItem.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

class PlaylistItem {
    
    enum State {
        case undefined
        case playback(TimeInterval)
    }
    
    let id: String
    let order: Int
    let audioFile: AudioFile
    var state: State

    init(id: String = UUID().uuidString,
         order: Int,
         audioFile: AudioFile,
         state: State) {
        
        self.id = id
        self.order = order
        self.state = state
        self.audioFile = audioFile
    }
}

extension PlaylistItem: Equatable {
    
    static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        return lhs.id == rhs.id && lhs.audioFile == rhs.audioFile
    }
}
