//
//  AppDependencies.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

protocol HasDropboxService {
    
    var dropboxService: DropboxService { get }
}

protocol HasAudioFileURLService {
    
    var audioFileURLService: AudioFileURLService { get }
}

protocol HasPlaybackController {
    
    var playbackController: PlaybackController { get }
}

protocol HasDatabaseService {
    
    var databaseService: DatabaseService { get }
}

protocol HasUserInfoProvider {
    
    var userInfoProvider: UserInfoProvider { get }
}

class AppDependencies {
    
    let dropboxService: DropboxService
    let audioFileURLService: AudioFileURLService
    let playbackController: PlaybackController
    let databaseService: DatabaseService
    let userInfoProvider: UserInfoProvider
    
    init(enviroments: Envitoments) {
        self.dropboxService = DropboxService(enviroments: enviroments)
        let audioFileURLService = AudioFileURLService(dropboxService: dropboxService)
        self.audioFileURLService = audioFileURLService
        let databaseService = DatabaseService(modelName: enviroments.coreDataModelName)
        self.databaseService = databaseService
        self.userInfoProvider = UserInfoProvider(dropboxService: dropboxService)
        self.playbackController = PlaybackController(audioFileURLService: audioFileURLService,
                                                     databaseService: databaseService)
    }
}

extension AppDependencies: HasDropboxService {}
extension AppDependencies: HasAudioFileURLService {}
extension AppDependencies: HasPlaybackController {}
extension AppDependencies: HasDatabaseService {}
extension AppDependencies: HasUserInfoProvider {}
