//
//  AudioFileTransform.swift
//  DropboxPlayer
//
//  Created by Oleg on 10/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

class AudioFileTransform: TransientEntiryTransform {
    typealias Entity = AudioFile
    
    func toEntity(_ entry: CDAudioFile) -> AudioFile? {
        
        guard let id = entry.id,
            let name = entry.name,
            let path = entry.pathLower else {
                return nil
        }
        return AudioFile(
            id: id,
            name: name,
            size: entry.size?.uint64Value ?? 0,
            pathLower: path,
            pathDisplay: entry.pathDisplay)
    }
    
    func toEntry(_ entity: AudioFile, in context: NSManagedObjectContext) -> CDAudioFile {
        
        let fetchRequest = entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", entity.id)
        let entry: CDAudioFile
        if let file = try? context.fetch(fetchRequest).first as? CDAudioFile {
            entry = file
        } else {
            let description = entity.entityDescription(in: context)
            entry = CDAudioFile(entity: description, insertInto: context)
            entry.id = entity.id
        }
        entry.name = entity.name
        entry.size = NSNumber(value: entity.size)
        entry.pathLower = entity.pathLower
        entry.pathDisplay = entity.pathDisplay
        return entry
    }
}
