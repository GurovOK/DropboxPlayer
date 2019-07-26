//
//  PlaybackController.swift
//  DropboxPlayer
//
//  Created by Oleg on 14/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class PlaybackController {
    
    typealias Dependencies = HasAudioFileURLService & HasPlaybackController & HasDatabaseService
    
    // MARK: - Properties
    
    private let audioFileURLService: AudioFileURLService
    private let databaseService: DatabaseService
    private var activePlaylist: Playlist?
    private let cloudPlayerFactory: DropboxPlayerFactory
    lazy var dropboxPlayer: DropboxPlayer = {
        return DropboxPlayerFactory.makeDropboxPlayer(audioFileURLService: audioFileURLService,
                                                      databaseService: databaseService)
    }()
    
    // MARK: - Init
    
    init(audioFileURLService: AudioFileURLService,
         databaseService: DatabaseService,
         cloudPlayerFactory: DropboxPlayerFactory = DropboxPlayerFactory()) {
        self.databaseService = databaseService
        self.audioFileURLService = audioFileURLService
        self.cloudPlayerFactory = cloudPlayerFactory
    }
    
    // MARK: - Public methods
    
    func startPlaying(_ playlist: Playlist) {
        
        var playlistChanged = true
        if let currentPlaylist = activePlaylist,
            playlist == currentPlaylist {
            playlistChanged = currentPlaylist.items.count != playlist.items.count ||
                zip(playlist.items, currentPlaylist.items).reduce(false, {
                    $0 && $1.0 != $1.1
                })
        }
        if playlistChanged {
            dropboxPlayer.setPlaylist(playlist)
        }
        activePlaylist = playlist
    }
    
    func clearPlayback() {
        dropboxPlayer.setPlaylist(nil)
    }
}
