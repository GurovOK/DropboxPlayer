//
//  AudioAssetURLFactory.swift
//  DropboxPlayer
//

import Foundation

class AudioAssetURLFactory {

    private struct Constants {
        static let dropboxFileScheme = "dropboxFile"
    }
    
    func makeAudioFileResourceURL(from file: AudioFile) -> URL? {
        guard let encodedPath = file.pathLower.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return nil
        }
        var components = URLComponents(string: encodedPath)
        components?.scheme = Constants.dropboxFileScheme
        return components?.url
    }
    
    func audioFilePath(from url: URL) -> String? {
        guard url.scheme == Constants.dropboxFileScheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        return components.path
    }
}
