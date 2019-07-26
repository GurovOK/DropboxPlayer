//
//  AudioFileCRUDOperation.swift
//  DropboxPlayer
//
//  Created by Oleg on 12/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

class AudioFileCRUDOperation: CRUDOperation {
    
    typealias Entity = AudioFile
    typealias Transform = AudioFileTransform
    
    let context: NSManagedObjectContext
    let transform: AudioFileTransform
    
    init(with context: NSManagedObjectContext, transform: AudioFileTransform) {
        self.context = context
        self.transform = transform
    }
}
