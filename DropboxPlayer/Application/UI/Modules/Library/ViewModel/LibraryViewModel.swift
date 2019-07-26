//
//  LibraryViewModel.swift
//  DropboxPlayer
//
//  Created by Oleg on 14/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol LibraryViewModelDelegate: class {
    
    func didSelectPlaylist()
    func didRequestToEdit(playlist: Playlist)
}

protocol LibraryViewModel: class {
    
    typealias State = ViewModelState<Void, Error>
    
    var title: String { get }
    var numberOfPlaylists: Int { get }
    var state: BehaviorRelay<State?> { get }
    var miniPlayerVisible: BehaviorRelay<Bool> { get }
    var miniPlayerViewModel: MiniPlayerViewModel { get }
    
    func addNewPlaylist()
    func requestPlaylists()
    func editPlaylist(at indexPath: IndexPath)
    func deletePlaylist(at indexPath: IndexPath)
    func selectPlaylist(at indexPath: IndexPath)
    func playlistCellViewModel(at indexPath: IndexPath) -> PlaylistTableCellViewModel?
}

class LibraryViewModelImplementation: LibraryViewModel {
    
    typealias Dependencies = HasDatabaseService & HasPlaybackController & HasUserInfoProvider
    
    // MARK: - Properties
    
    let title: String
    var numberOfPlaylists: Int {
        return playlists.count
    }
    let miniPlayerViewModel: MiniPlayerViewModel
    let state = BehaviorRelay<State?>(value: nil)
    var miniPlayerVisible: BehaviorRelay<Bool> {
        return miniPlayerViewModel.isPlaybackAvailable
    }
    weak var delegate: LibraryViewModelDelegate?
    
    private let dependencies: Dependencies
    private var databaseService: DatabaseService {
        return dependencies.databaseService
    }
    private var playlists: [Playlist] = []
    private var currentUser: User?
    private var disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(title: String,
         dependencies: Dependencies,
         miniPlayerViewModel: MiniPlayerViewModel) {
        self.title = title
        self.dependencies = dependencies
        self.miniPlayerViewModel = miniPlayerViewModel
    }
    
    // MARK: - Public methods
    
    func addNewPlaylist() {
        guard let user = currentUser else { return }
        let playlist = Playlist(name: "Новый плейлист".localized(),
                                items: [],
                                accountId: user.accountId)
        delegate?.didRequestToEdit(playlist: playlist)
    }
    
    func requestPlaylists() {
        state.accept(.loading)
        dependencies
            .userInfoProvider
            .getUserInfo()
            .subscribe(onSuccess: { user in
                self.currentUser = user
                self.playlists = self.databaseService.getAllPlaylists(forAccount: user.accountId)
                if self.playlists.isEmpty {
                    self.state.accept(.noData)
                } else {
                    self.state.accept(.dataReady(nil))
                }
            }, onError: { error in
                self.state.accept(.error(error))
            }).disposed(by: disposeBag)
    }
    
    func selectPlaylist(at indexPath: IndexPath) {
        guard let playlist = playlist(at: indexPath) else {
            return
        }
        dependencies.playbackController.startPlaying(playlist)
    }
    
    func playlistCellViewModel(at indexPath: IndexPath) -> PlaylistTableCellViewModel? {
        guard let playlist = playlist(at: indexPath) else {
            return nil
        }
        return PlaylistTableCellViewModel(name: playlist.name)
    }
    
    func editPlaylist(at indexPath: IndexPath) {
        guard let playlist = playlist(at: indexPath) else {
            return
        }
        delegate?.didRequestToEdit(playlist: playlist)
    }
    
    func deletePlaylist(at indexPath: IndexPath) {
        guard let playlist = playlist(at: indexPath) else {
            return
        }
        databaseService.delete(playlist: playlist)
        requestPlaylists()
    }
    
    // MARK: - Private methods
    
    private func playlist(at indexPath: IndexPath) -> Playlist? {
        guard indexPath.row >= 0, indexPath.row < numberOfPlaylists else {
            return nil
        }
        return playlists[indexPath.row]
    }
}
