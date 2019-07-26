//
//  AuthorizationViewModel.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol AuthorizationViewModelDelegate: class {
    
    func authorizationViewModelDidAuthorize(_ viewModel: AuthorizationViewModel)
}

enum AuthorizationViewModelError: Error {
    case cancelled
    case dropboxError(Error)
}

protocol AuthorizationViewModel {
    
    typealias State = ViewModelState<Void, AuthorizationViewModelError>
    
    var state: BehaviorRelay<State?> { get }
    
    func authorize()
}

class AuthorizationViewModelImplementation: AuthorizationViewModel {
    
    // MARK: - Properties
    
    weak var delegate: AuthorizationViewModelDelegate?
    let state: BehaviorRelay<AuthorizationViewModel.State?> = BehaviorRelay(value: nil)
    
    private let authorizationHelper: DropboxAuthorizationHelper
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(authorizationHelper: DropboxAuthorizationHelper) {
        self.authorizationHelper = authorizationHelper
    }
    
    // MARK: - Public
    
    func authorize() {
        state.accept(.loading)
        authorizationHelper
            .authorize()
            .subscribe(onNext: { isAuthorized in
                if isAuthorized {
                    self.state.accept(.dataReady(nil))
                    self.delegate?.authorizationViewModelDidAuthorize(self)
                } else {
                    self.state.accept(.error(.cancelled))
                }
            }, onError: { error in
                self.state.accept(.error(AuthorizationViewModelError.dropboxError(error)))
            }).disposed(by: disposeBag)
    }
}
