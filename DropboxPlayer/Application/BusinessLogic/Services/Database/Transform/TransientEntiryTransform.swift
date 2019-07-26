//
//  TransientEntiryTransform.swift
//  DropboxPlayer
//
//  Created by Oleg on 10/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

protocol TransientEntiryTransform {
    associatedtype Entity: TransientEntity
    
    func toEntity(_ entry: Entity.Entry) -> Entity?
    func toEntry(_ entity: Entity, in context: NSManagedObjectContext) -> Entity.Entry
}
