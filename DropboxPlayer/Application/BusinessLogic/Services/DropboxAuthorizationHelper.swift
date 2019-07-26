//
//  DropboxAuthorizationHelper.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum DropboxAuthorizationHelperError: Error {
    case targetRequired
}

class DropboxAuthorizationHelper {
    
    typealias Dependencies = HasDropboxService
    
    // MARK: - Properties
    
    private let dependencies: Dependencies
    private weak var target: UIViewController?
    
    // MARK: - Init
    
    init(dependencies: Dependencies, target: UIViewController) {
        self.dependencies = dependencies
        self.target = target
    }
    
    // MARK: - Public
    
    func authorize() -> PublishSubject<Bool> {
        guard let target = target else {
            let subj = PublishSubject<Bool>()
            subj.on(.error(DropboxAuthorizationHelperError.targetRequired))
            return subj
        }
        return dependencies.dropboxService.startAuthFlow(with: target)
    }
}
