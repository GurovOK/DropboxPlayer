//
//  PlaylistItemTransform.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

class PlaylistItemTransform: TransientEntiryTransform {
    typealias Entity = PlaylistItem
    
    private let audioFileTransform: AudioFileTransform
    
    init(audioFileTransform: AudioFileTransform) {
        self.audioFileTransform = audioFileTransform
    }
    
    func toEntity(_ entry: CDPlaylistItem) -> PlaylistItem? {
        
        guard let id = entry.id,
            let audioFile = entry.audioFile,
            let audioFileEntry = audioFileTransform.toEntity(audioFile) else {
                return nil
        }
        let state: PlaylistItem.State
        if let timeInterval = entry.playbackTime?.doubleValue {
            state = .playback(timeInterval)
        } else {
            state = .undefined
        }
        return PlaylistItem(
            id: id,
            order: entry.orderId?.intValue ?? 0,
            audioFile: audioFileEntry,
            state: state)
    }
    
    func toEntry(_ entity: PlaylistItem, in context: NSManagedObjectContext) -> CDPlaylistItem {
        
        let fetchRequest = entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", entity.id)
        let entry: CDPlaylistItem
        if let item = try? context.fetch(fetchRequest).first as? CDPlaylistItem {
            entry = item
        } else {
            let description = entity.entityDescription(in: context)
            entry = CDPlaylistItem(entity: description, insertInto: context)
            entry.id = entity.id
        }
        entry.orderId = NSNumber(value: entity.order)
        entry.audioFile = audioFileTransform.toEntry(entity.audioFile, in: context)
        if case let .playback(time) = entity.state {
            entry.playbackTime = NSNumber(value: time)
        } else {
            entry.playbackTime = nil
        }
        return entry
    }
}
