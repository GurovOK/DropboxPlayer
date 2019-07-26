//
//  AudioFileRedirectTask.swift
//  DropboxPlayer
//
//  Created by Oleg on 02/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import AVFoundation
import CoreServices
import RxSwift

enum AudioFileLoadingTaskError: Error {
    case cancelled
}

private enum AudioFileLoadingState {
    case undefined
    case urlObrained(URL)
}

protocol AudioFileRedirectTaskDelegate: class {
    
    func audioFileRedirectTaskDidFinished(_ task: AudioFileRedirectTask)
}

class AudioFileRedirectTask {
    
    private struct Constants {
        static let redirectCode = 302
    }
    
    // MARK: Properties
    
    private var urlRequestDisposable: Disposable?
    private let disposeBag = DisposeBag()
    private let urlFactory: AudioAssetURLFactory
    private let audioFileURLService: AudioFileURLService
    private var requests: [AVAssetResourceLoadingRequest] = []
    private var fileLoadingState: AudioFileLoadingState = .undefined
    private var isFileURLRequestInProcess: Bool = false
    
    let requestURL: URL
    weak var delegate: AudioFileRedirectTaskDelegate?
    
    // MARK: - Init
    
    init(audioFileURLService: AudioFileURLService,
         urlFactory: AudioAssetURLFactory = AudioAssetURLFactory(),
         requestURL: URL) {
        self.audioFileURLService = audioFileURLService
        self.urlFactory = urlFactory
        self.requestURL = requestURL
    }
    
    deinit {
        urlRequestDisposable?.dispose()
        urlRequestDisposable = nil
    }
  
    // MARK: Public methods
    
    func addRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard loadingRequest.request.url == requestURL else {
            return
        }
        requests.append(loadingRequest)
        processLoadingRequest(loadingRequest)
    }
    
    func cancel(loadingRequest: AVAssetResourceLoadingRequest) {
        if let index = requests.firstIndex(of: loadingRequest) {
            if !loadingRequest.isFinished {
                loadingRequest.finishLoading(with: AudioFileLoadingTaskError.cancelled)
            }
            requests.remove(at: index)
        }
        if requests.isEmpty {
            urlRequestDisposable?.dispose()
            urlRequestDisposable = nil
            delegate?.audioFileRedirectTaskDidFinished(self)
        }
    }
    
    // MARK: - Private methods
    
    private func processLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        switch fileLoadingState {
        case .undefined:
            requestAudioFileURL(for: loadingRequest)
        case .urlObrained(let fileURL):
            processRequestsWith(redirectURL: fileURL)
        }
    }
    
    private func requestAudioFileURL(for loadingRequest: AVAssetResourceLoadingRequest) {
        guard let requestURL = loadingRequest.request.url,
            let filePath = urlFactory.audioFilePath(from: requestURL),
            !isFileURLRequestInProcess else {
                return
        }
        isFileURLRequestInProcess = true
        urlRequestDisposable = audioFileURLService
            .url(forPath: filePath)
            .subscribe(onSuccess: { [weak self] fileURL in
                guard let self = self else { return }
                self.isFileURLRequestInProcess = false
                self.fileLoadingState = .urlObrained(fileURL)
                self.processRequestsWith(redirectURL: fileURL)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.isFileURLRequestInProcess = false
                self.finishLoadingRequests(withError: error)
            })
    }
    
    private func processRequestsWith(redirectURL: URL) {
        requests.forEach {
            if !$0.isFinished {
                $0.redirect = URLRequest(url: redirectURL)
                $0.response = HTTPURLResponse(url: redirectURL,
                                              statusCode: Constants.redirectCode,
                                              httpVersion: nil,
                                              headerFields: nil)
                $0.finishLoading()
            }
        }
        removeFinishedRequests()
    }
    
    private func finishLoadingRequests(withError error: Error) {
        requests.forEach {
            if !$0.isFinished {
                $0.finishLoading(with: error)
            }
        }
        removeFinishedRequests()
    }
    
    private func removeFinishedRequests() {
        requests = requests.filter { !$0.isFinished }
        if requests.isEmpty {
            delegate?.audioFileRedirectTaskDidFinished(self)
        }
    }
}
