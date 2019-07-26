//
//  DropboxService.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import UIKit
import SwiftyDropbox
import RxCocoa
import RxSwift

protocol DropboxEnvitoments {
    
    var dropboxAppKey: String { get }
    var dropboxAppSecret: String { get }
}

protocol DropboxServiceDelegate: class {
    
    func dropboxServiceDidHandleUnauthorizeError(_ service: DropboxService)
}

class DropboxService {
    
    private struct Constants {
        static let dropboxDownloadParamKey = "dl"
        static let dropboxDownloadParamValue = "1"
        static let unauthorizadCode = 401
    }
    
    // MARK: - Properties
    
    weak var delegate: DropboxServiceDelegate?
    var isAuthorized: Bool {
        return client != nil
    }
    
    private var client: DropboxClient? {
        return DropboxClientsManager.authorizedClient
    }
    private var authSubject: PublishSubject<Bool>?
    
    // MARK: - Init
    
    init(enviroments: DropboxEnvitoments) {
        DropboxClientsManager.setupWithAppKey(enviroments.dropboxAppKey)
    }
    
    // MARK: - Private methods
    
    private func handleAuthorizationError<T>(from request: Single<T>) -> Single<T> {
        return request.catchError { error in
            if (error as NSError).code == Constants.unauthorizadCode {
                self.delegate?.dropboxServiceDidHandleUnauthorizeError(self)
            }
            return Single.error(error)
        }
    }
}

// MARK: - Authorization
extension DropboxService {
    
    func startAuthFlow(with controller: UIViewController) -> PublishSubject<Bool> {
        DropboxClientsManager.authorizeFromController(
            UIApplication.shared,
            controller: controller,
            openURL: { (url: URL) -> Void in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        let subject = PublishSubject<Bool>()
        authSubject = subject
        return subject
    }
    
    func handle(open url: URL) {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            switch authResult {
            case .success:
                authSubject?.onNext(true)
                authSubject?.on(.completed)
            case .cancel:
                authSubject?.onNext(false)
                authSubject?.on(.completed)
            case .error(let error, _):
                authSubject?.onError(error.dropboxServiceError)
            }
            authSubject = nil
        }
    }
    
    func logout() -> Single<Void> {
        guard let client = self.client else {
            return Single.just(())
        }
        let request: Single<Void> = Single.create { single -> Disposable in
            let request = client.auth.tokenRevoke().response { _, error in
                if let error = error {
                    single(.error(error.dropboxServiceError))
                } else {
                    DropboxClientsManager.unlinkClients()
                    single(.success(()))
                }
            }
            return Disposables.create {
                request.cancel()
            }
        }
        return handleAuthorizationError(from: request)
    }
}

// MARK: - Files
extension DropboxService {
    
    func requestFileList(withPath path: String = "") -> Single<[FileType]> {
        guard let client = self.client else {
            return Single.error(DropboxServiceError.unauthorizedClient)
        }
        let request: Single<[FileType]> = Single.create { single -> Disposable in
            let request = client.files.listFolder(
                path: path,
                includeMediaInfo: true)
                .response(completionHandler: { (result, error) in
                    guard let result = result else {
                        single(.error(error?.dropboxServiceError ?? DropboxServiceError.unknown))
                        return
                    }
                    let filesMetadata: [FileType] = result.entries.compactMap { metadata in
                        FileType(metadata: metadata)
                    }
                    single(.success(filesMetadata))
                })
            return Disposables.create {
                request.cancel()
            }
        }
        return handleAuthorizationError(from: request)
    }
    
    func getTemporaryLink(path: String) -> Single<URL> {
        guard let client = self.client else {
            return Single.error(DropboxServiceError.unauthorizedClient)
        }
        let request: Single<URL> = Single.create { single -> Disposable in
            let request = client
                .files
                .getTemporaryLink(path: path)
                .response { (result, error) in
                    if let result = result {
                        if let fileURL = URL(string: result.link) {
                            single(.success(fileURL))
                        } else {
                            single(.error(DropboxServiceError.urlObtainingError))
                        }
                    } else {
                        single(.error(error?.dropboxServiceError ?? DropboxServiceError.unknown))
                    }
            }
            return Disposables.create {
                request.cancel()
            }
        }
        return handleAuthorizationError(from: request)
    }
}

// MARK: - User info
extension DropboxService {
    
    func getUserInfo() -> Single<User> {
        guard let client = self.client else {
            return Single.error(DropboxServiceError.unauthorizedClient)
        }
        let request: Single<User> = Single.create { single -> Disposable in
            let request = client
                .users
                .getCurrentAccount()
                .response(completionHandler: { account, error in
                    if let account = account {
                        let user = User(accountId: account.accountId,
                                        name: account.name.displayName,
                                        email: account.email)
                        single(.success(user))
                    } else {
                        single(.error(error?.dropboxServiceError ?? DropboxServiceError.unknown))
                    }
            })
            return Disposables.create {
                request.cancel()
            }
        }
        return handleAuthorizationError(from: request)
        
    }
    
    func getSpaceUsageInfo() -> Single<SpaceUsageInfo> {
        guard let client = self.client else {
            return Single.error(DropboxServiceError.unauthorizedClient)
        }
        let request: Single<SpaceUsageInfo> = Single.create { single -> Disposable in
            let request = client.users.getSpaceUsage().response { spaceUsage, error in
                if let spaceUsage = spaceUsage {
                    var allocated: UInt64?
                    switch spaceUsage.allocation {
                    case .individual(let allocation):
                        allocated = allocation.allocated
                    case .team(let allocation):
                        allocated = allocation.allocated
                    case .other:
                        break
                    }
                    let info = SpaceUsageInfo(allocated: allocated, used: spaceUsage.used)
                    single(.success(info))
                } else {
                    single(.error(error?.dropboxServiceError ?? DropboxServiceError.unknown))
                }
            }
            return Disposables.create {
                request.cancel()
            }
        }
        return handleAuthorizationError(from: request)
    }
}
