//
//  AudioAssetsLoader.swift
//  DropboxPlayer
//
//  Created by Oleg on 02/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import AVFoundation

class AudioAssetsLoader: NSObject {
    
    // MARK: Properties
    
    private typealias FileInfo = (UInt64, String)
    
    private let audioFileURLService: AudioFileURLService
    private let urlFactory: AudioAssetURLFactory
    private var loadingTasks: [URL: AudioFileRedirectTask] = [:]
    
    // MARK: Init
    
    init(audioFileURLService: AudioFileURLService,
         urlFactory: AudioAssetURLFactory = AudioAssetURLFactory()) {
        self.audioFileURLService = audioFileURLService
        self.urlFactory = urlFactory
    }
    
    // MARK: Public methods
  
    func assetForURL(_ url: URL) -> AVURLAsset {
        let asset = AVURLAsset(url: url)
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        return asset
    }
  
    // MARK: Private methods
  
    private func loadingTask(for url: URL) -> AudioFileRedirectTask? {
        return loadingTasks[url]
    }
}

// MARK: AVAssetResourceLoaderDelegate
extension AudioAssetsLoader: AVAssetResourceLoaderDelegate {
  
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                      shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return shouldWaitForLoadingOfRequestedResource(loadingRequest)
    }
  
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return shouldWaitForLoadingOfRequestedResource(renewalRequest)
    }
  
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let requestURL = loadingRequest.request.url else { return }
        if let task = loadingTask(for: requestURL) {
            task.cancel(loadingRequest: loadingRequest)
        }
    }
    
    private func removeLoadingTask(for url: URL) {
        loadingTasks.removeValue(forKey: url)
    }
    
    private func shouldWaitForLoadingOfRequestedResource(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        return processLoadingRequest(loadingRequest)
    }
    
    private func processLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let requestURL = loadingRequest.request.url else {
            return false
        }
        let task: AudioFileRedirectTask
        if let loadingTask = loadingTask(for: requestURL) {
            task = loadingTask
        } else {
            task = AudioFileRedirectTask(audioFileURLService: audioFileURLService, requestURL: requestURL)
            task.delegate = self
            loadingTasks[requestURL] = task
        }
        task.addRequest(loadingRequest)
        return true
    }
}

extension AudioAssetsLoader: AudioFileRedirectTaskDelegate {
    
    func audioFileRedirectTaskDidFinished(_ task: AudioFileRedirectTask) {
        removeLoadingTask(for: task.requestURL)
    }
}
