//
//  PlaylistTransform.swift
//  DropboxPlayer
//
//  Created by Oleg on 10/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

class PlaylistTransform: TransientEntiryTransform {
    typealias Entity = Playlist
    
    private let playlistItemTransform: PlaylistItemTransform
    
    init(playlistItemTransform: PlaylistItemTransform) {
        self.playlistItemTransform = playlistItemTransform
    }
    
    func toEntity(_ entry: CDPlaylist) -> Playlist? {
        
        guard let id = entry.id,
            let name = entry.name,
            let accountId = entry.accountId else {
            return nil
        }
        let itemsSet = entry.items ?? NSSet()
        let items: [PlaylistItem] = Array(itemsSet).compactMap {
            guard let entry = $0 as? CDPlaylistItem else { return nil }
            return playlistItemTransform.toEntity(entry)
        }.sorted { $0.order < $1.order }
        return Playlist(id: id, name: name, items: items, accountId: accountId)
    }
    
    func toEntry(_ entity: Playlist, in context: NSManagedObjectContext) -> CDPlaylist {
        
        let fetchRequest = entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", entity.id)
        let entry: CDPlaylist
        if let playlist = try? context.fetch(fetchRequest).first as? CDPlaylist {
            entry = playlist
        } else {
            let description = entity.entityDescription(in: context)
            entry = CDPlaylist(entity: description, insertInto: context)
            entry.id = entity.id
            entry.accountId = entity.accountId
        }
        entry.name = entity.name
        let items = entity.items.map {
            playlistItemTransform.toEntry($0, in: context)
        }
        entry.items = NSSet(array: items)
        return entry
    }
}
