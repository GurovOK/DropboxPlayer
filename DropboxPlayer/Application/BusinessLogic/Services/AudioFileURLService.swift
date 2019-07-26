//
//  AudioFileURLService.swift
//  DropboxPlayer
//
//  Created by Oleg on 25/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class AudioFileURLService {

    private struct Constants {
        static let defaultCacheLifetime: TimeInterval = 60 * 60 * 3.5
    }
    
    // MARK: - Properties
    
    private let cache = NSCache<NSString, URLCacheValue>()
    private let dropboxService: DropboxService
    private let cacheLifetime: TimeInterval
    
    // MARK: - Init
    
    init(dropboxService: DropboxService,
         cacheLifetime: TimeInterval = Constants.defaultCacheLifetime) {
        self.dropboxService = dropboxService
        self.cacheLifetime = cacheLifetime
    }
    
    // MARK: - Public methods
    
    func url(for file: AudioFile) -> Single<URL> {
        
        return url(forPath: file.pathLower)
    }
    
    func url(forPath filePath: String) -> Single<URL> {
        
        if let url = getCachedURL(forPath: filePath) {
            return Single.just(url)
        } else {
            return dropboxService
                .getTemporaryLink(path: filePath)
                .do(onSuccess: { url in
                    let cacheValue = URLCacheValue(url: url, timestamp: Date().timeIntervalSinceReferenceDate)
                    self.cache.setObject(cacheValue, forKey: (filePath as NSString))
                })
        }
    }
    
    // MARK: - Private methods
    
    private func getCachedURL(forPath filePath: String) -> URL? {
        guard let cachedValue = cache.object(forKey: (filePath as NSString)),
            Date().timeIntervalSinceReferenceDate - cachedValue.timestamp < cacheLifetime else {
            return nil
        }
        return cachedValue.audioFileURL
    }
}

private class URLCacheValue {
    
    // MARK: - Properties
    
    let audioFileURL: URL
    let timestamp: TimeInterval
    
    // MARK: - Init
    
    init(url: URL, timestamp: TimeInterval) {
        self.audioFileURL = url
        self.timestamp = timestamp
    }
}
