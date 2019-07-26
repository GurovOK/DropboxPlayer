//
//  TrackInfo.swift
//  DropboxPlayer
//
//  Created by Oleg on 15/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

struct TrackInfo {
    
    typealias PositionInfo = (trackIndex: Int, totalTracksCount: Int)
    
    let albumName: String?
    let trackName: String?
    let artworkData: Data?
    let playlistName: String
    let positionInfo: PositionInfo
    var positionInfoString: String? {
        guard positionInfo.totalTracksCount > 1 else {
            return nil
        }
        return "\(positionInfo.trackIndex + 1) / \(positionInfo.totalTracksCount)"
    }
    
    init(trackFileName: String,
         playlistName: String,
         albumName: String? = nil,
         artworkData: Data? = nil,
         positionInfo: PositionInfo) {
        self.trackName = trackFileName
        self.playlistName = playlistName
        self.albumName = albumName
        self.artworkData = artworkData
        self.positionInfo = positionInfo
    }
}

struct TrackTimeInfo {
    
    let currentTime: TimeInterval
    let duration: TimeInterval
}

extension TrackInfo {
    
    init(playlistName: String,
         metadata: AudioPlayerItemMetadata,
         positionInfo: PositionInfo) {
        self.albumName = metadata.album
        self.trackName = metadata.title
        self.artworkData = metadata.artworkData
        self.playlistName = playlistName
        self.positionInfo = positionInfo
    }
}
