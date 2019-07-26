//
//  UserInfoProvider.swift
//  DropboxPlayer
//
//  Created by Oleg on 23/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift

class UserInfoProvider {
    
    // MARK: - Properties
    
    private let dropboxService: DropboxService
    private var user: User?
    
    // MARK: - Init
    
    init(dropboxService: DropboxService) {
        self.dropboxService = dropboxService
    }
    
    // MAKR: - Private
    
    func getUserInfo() -> Single<User> {
        if let user = user {
            return Single.just(user)
        } else {
            return dropboxService
                .getUserInfo()
                .do(onSuccess: { user in
                    self.user = user
                })
        }
    }
    
    func clearCachedUserInfo() {
        user = nil
    }
}
