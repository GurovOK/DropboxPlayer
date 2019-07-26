//
//  DatabaseService.swift
//  DropboxPlayer
//
//  Created by Oleg on 09/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import CoreData

class DatabaseService {
    
    private struct Constants {
        static let defaultModelName = "Model"
    }
    
    private let container: NSPersistentContainer
    
    init(modelName: String = Constants.defaultModelName) {
        
        container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { description, error in
            
            if let error = error {
                fatalError("unable to load persistent store \(error)")
            }
        }
    }
}

extension DatabaseService {
    
    private func makeAudioFileTransform() -> AudioFileTransform {
        return AudioFileTransform()
    }
    
    private func makePlaylistItemTransform() -> PlaylistItemTransform {
        return PlaylistItemTransform(audioFileTransform: makeAudioFileTransform())
    }
    
    private func makePlaylistTransform() -> PlaylistTransform {
        return PlaylistTransform(playlistItemTransform: makePlaylistItemTransform())
    }
    
    private func makePlaylistOperation() -> PlaylistCRUDOperation {
        return PlaylistCRUDOperation(
            with: container.viewContext,
            transform: makePlaylistTransform())
    }
    
    func getAllPlaylists(forAccount accountId: String) -> [Playlist] {
        let operation = makePlaylistOperation()
        let predicate = NSPredicate(format: "accountId == %@", accountId)
        return operation.getAll(with: predicate)
    }
    
    func getAllActivePlaylists(forAccount accountId: String) -> [Playlist] {
        let operation = makePlaylistOperation()
        let predicate = NSPredicate(format: "(accountId == %@) AND (ANY items.playbackTime != nil)", accountId)
        return operation.getAll(with: predicate)
    }
    
    func save(playlist: Playlist) {
        let operation = makePlaylistOperation()
        operation.save([playlist])
    }
    
    func save(playlists: [Playlist]) {
        let operation = makePlaylistOperation()
        operation.save(playlists)
    }
    
    func delete(playlist: Playlist) {
        let operation = makePlaylistOperation()
        operation.delete([playlist])
    }
}
