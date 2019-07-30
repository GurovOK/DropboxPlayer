//
//  TrackInfo.swift
//  DropboxPlayer
//
//  Created by Oleg on 15/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

struct TrackInfo: Equatable {
    
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
    
    static func == (lhs: TrackInfo, rhs: TrackInfo) -> Bool {
        return lhs.albumName == rhs.albumName &&
        lhs.trackName == rhs.trackName &&
        lhs.artworkData == rhs.artworkData &&
        lhs.playlistName == rhs.playlistName &&
        lhs.positionInfo == rhs.positionInfo
    }
}

struct TrackTimeInfo: Equatable {
    
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
