//
//  CRUDOperation.swift
//  DropboxPlayer
//
//  Created by Oleg on 10/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

protocol CRUDOperation {
    
    associatedtype Entity: TransientEntity
    associatedtype Transform: TransientEntiryTransform
    
    var context: NSManagedObjectContext { get }
    var transform: Transform { get }
    
    func getAll(with predicate: NSPredicate?) -> [Entity]
    func save(_ entities: [Entity])
    func delete(_ entities: [Entity])
}

extension CRUDOperation where Entity: TransientEntity, Transform: TransientEntiryTransform, Transform.Entity == Entity {
    
    func save(_ entities: [Entity]) {
        
        let entries = entities.map {
            transform.toEntry($0, in: context)
        }
        guard !entries.isEmpty else { return }
        do {
            try context.save()
        } catch {
            fatalError("Saving of \(String(describing: self)) failed with \(error)")
        }
    }
    
    func getAll(with predicate: NSPredicate?) -> [Entity] {
        
        let fetchRequest = NSFetchRequest<Entity.Entry>(entityName: String(describing: Entity.Entry.self))
        fetchRequest.predicate = predicate
        let list: [Entity.Entry]
        do {
            list = try context.fetch(fetchRequest)
        } catch {
            fatalError("Fetching of \(String(describing: self)) failed")
        }
        return list.compactMap {
            transform.toEntity($0)
        }
    }
    
    func delete(_ entities: [Entity]) {
        
        let entries = entities.map {
            transform.toEntry($0, in: context)
        }
        guard !entries.isEmpty else { return }
        entries.forEach {
            context.delete($0)
        }
        do {
            try context.save()
        } catch {
            fatalError("Saving of \(String(describing: self)) failed")
        }
    }
}
