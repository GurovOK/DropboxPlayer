//
//  DropboxPlayerFactory.swift
//  DropboxPlayer
//
//  Created by Oleg on 07/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

class DropboxPlayerFactory {
    
    static func makeDropboxPlayer(audioFileURLService: AudioFileURLService,
                                  databaseService: DatabaseService) -> DropboxPlayer {
        return DropboxPlayerImplementation(with: audioFileURLService,
                                           databaseService: databaseService,
                                           remoteCommandCenter: PlayerRemoteCommandCenter())
    }
}
