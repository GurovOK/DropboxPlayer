//
//  AudioFile.swift
//  DropboxPlayer
//
//  Created by Oleg on 22/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

struct AudioFile {
    
    let id: String
    let name: String
    let size: UInt64
    let pathLower: String
    let pathDisplay: String?
}

extension AudioFile: Equatable {
    
    static func == (lhs: AudioFile, rhs: AudioFile) -> Bool {
        return lhs.id == rhs.id
    }
}
