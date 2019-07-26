//
//  ProfileViewModel.swift
//  DropboxPlayer
//
//  Created by Oleg on 18/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum ProfileError: Error {
    case profileRequestFailed
    case logoutFailed
}

protocol ProfileViewModelDelegate: class {
    
    func profileViewModelDidLogout(_ viewModel: ProfileViewModel)
}

protocol ProfileViewModel: class {
    
    typealias ProfileInfo = (user: User, spaceUsageInfo: SpaceUsageInfo)
    
    typealias State = ViewModelState<ProfileInfo, ProfileError>
    
    var isLogoutInProgress: BehaviorRelay<Bool> { get }
    var state: BehaviorRelay<State?> { get }
    
    func requestProfileInfo()
    func logout()
}

class ProfileViewModelImplementation: ProfileViewModel {
    
    typealias Dependencies = HasDatabaseService & HasDropboxService & HasUserInfoProvider
    
    // MARK: - Properties
    
    weak var delegate: ProfileViewModelDelegate?
    let isLogoutInProgress = BehaviorRelay(value: false)
    let state = BehaviorRelay<State?>(value: nil)
    
    private let dependencies: Dependencies
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Public methods
    
    func requestProfileInfo() {
        state.accept(.loading)
        let userInfoRequest = dependencies.userInfoProvider.getUserInfo().asObservable()
        let storageInfoRequest = dependencies.dropboxService.getSpaceUsageInfo().asObservable()
        Observable.combineLatest(userInfoRequest, storageInfoRequest)
            .subscribe(onNext: { info in
                self.state.accept(.dataReady(info))
            }, onError: { _ in
                self.state.accept(.error(.profileRequestFailed))
            }).disposed(by: disposeBag)
    }
    
    func logout() {
        isLogoutInProgress.accept(true)
        dependencies
            .dropboxService
            .logout()
            .subscribe(onSuccess: { _ in
                self.isLogoutInProgress.accept(false)
                self.delegate?.profileViewModelDidLogout(self)
            }, onError: { error in
                self.isLogoutInProgress.accept(false)
                self.state.accept(.error(.logoutFailed))
            }).disposed(by: disposeBag)
    }
}
