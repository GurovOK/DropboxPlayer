//
//  PlaylistCRUDOperation.swift
//  DropboxPlayer
//
//  Created by Oleg on 12/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

class PlaylistCRUDOperation: CRUDOperation {
    
    typealias Entity = Playlist
    typealias Transform = PlaylistTransform
    
    let context: NSManagedObjectContext
    let transform: PlaylistTransform
    
    init(with context: NSManagedObjectContext, transform: PlaylistTransform) {
        self.context = context
        self.transform = transform
    }
}
