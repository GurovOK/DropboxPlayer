//
//  TransientEntity.swift
//  DropboxPlayer
//
//  Created by Oleg on 10/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

protocol TransientEntity {
    associatedtype Entry: NSManagedObject
}

extension Playlist: TransientEntity {
    typealias Entry = CDPlaylist
}

extension AudioFile: TransientEntity {
    typealias Entry = CDAudioFile
}

extension PlaylistItem: TransientEntity {
    typealias Entry = CDPlaylistItem
}

extension TransientEntity {
    
    private var entryName: String {
        return String(describing: Entry.self)
    }
    func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        guard let description = NSEntityDescription.entity(
            forEntityName: entryName,
            in: context) else {
            fatalError("unable to create entity description for \(Entry.self)")
        }
        return description
    }
    
    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: entryName)
    }
}
