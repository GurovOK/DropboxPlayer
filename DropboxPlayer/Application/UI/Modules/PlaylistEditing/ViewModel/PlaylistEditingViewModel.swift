//
//  PlaylistEditingViewModel.swift
//  DropboxPlayer
//
//  Created by Oleg on 15/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol PlaylistEditingViewModelDelegate: class {
    
    func didSavePlaylist()
    func didRequestToClose()
    func didRequestToSelectFiles()
}

protocol PlaylistEditingViewModel: class {
    
    typealias State = ViewModelState<Void, Error>
    
    var name: String? { get }
    var numberOfFiles: Int { get }
    var state: BehaviorRelay<State?> { get }
    var isSaveButtonEnabled: BehaviorRelay<Bool> { get }
    
    func save()
    func cancel()
    func addFiles()
    func appendFiles(_ files: [AudioFile])
    func deleteFile(at indexPath: IndexPath)
    func changePlaylistName(_ name: String?)
    func fileCellViewModel(at indexPath: IndexPath) -> FileCellViewModel?
    func moveRow(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
}

class PlaylistEditingViewModelImplementation: PlaylistEditingViewModel {
    
    typealias Dependencies = HasDatabaseService & HasDropboxService
    
    // MARK: - Properties
    
    private(set) var name: String?
    var numberOfFiles: Int {
        return items.count
    }
    var isSaveButtonEnabled = BehaviorRelay<Bool>(value: false)
    var state = BehaviorRelay<State?>(value: nil)
    weak var delegate: PlaylistEditingViewModelDelegate?
    
    private var playlist: Playlist
    private var items: [PlaylistItem]
    private let dependencies: Dependencies
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(with playlist: Playlist, dependencies: Dependencies) {
        
        self.name = playlist.name
        self.playlist = playlist
        self.items = playlist.items
        self.dependencies = dependencies
        updateDataState()
        validate()
    }
    
    // MARK: - Public methods
    
    func save() {
        guard let name = self.name, !name.isEmpty else {
            return
        }
        
        playlist.name = name
        playlist.items = items
        dependencies.databaseService.save(playlist: playlist)
        delegate?.didSavePlaylist()
    }
    
    func cancel() {
        delegate?.didRequestToClose()
    }
    
    func addFiles() {
        delegate?.didRequestToSelectFiles()
    }
    
    func appendFiles(_ files: [AudioFile]) {
        let filteredFiles = files.filter { file in
            !self.items.contains(where: { $0.audioFile == file })
        }
        guard !filteredFiles.isEmpty else { return }
        filteredFiles.forEach {
            items.append(PlaylistItem(
                order: self.items.count,
                audioFile: $0,
                state: .undefined))
        }
        updateDataState()
        validate()
    }
    
    func deleteFile(at indexPath: IndexPath) {
        guard indexPath.row >= 0, indexPath.row < numberOfFiles else {
            return
        }
        var newItems = items
        newItems.remove(at: indexPath.row)
        items = newItems.enumerated().map { offset, item in
            return PlaylistItem(id: item.id,
                                order: offset,
                                audioFile: item.audioFile,
                                state: item.state)
        }
        updateDataState()
        validate()
    }
    
    func fileCellViewModel(at indexPath: IndexPath) -> FileCellViewModel? {
        guard indexPath.row >= 0, indexPath.row < numberOfFiles else {
            return nil
        }
        let item = items[indexPath.row]
        return FileCellViewModelFactory.makeFileCellViewModel(with: .file(item.audioFile))
    }
    
    func moveRow(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let indexes: [Int] = Array(0..<numberOfFiles)
        guard indexes.contains(sourceIndexPath.row),
            indexes.contains(destinationIndexPath.row) else {
                return
        }
        var newItems = items
        let item = items[sourceIndexPath.row]
        newItems.remove(at: sourceIndexPath.row)
        newItems.insert(item, at: destinationIndexPath.row)
        items = newItems.enumerated().map{ offset, item in
            PlaylistItem(id: item.id,
                         order: offset,
                         audioFile: item.audioFile,
                         state: item.state)
        }
    }
    
    func changePlaylistName(_ name: String?) {
        self.name = name
        validate()
    }
    
    // MARK: - Private methods
    
    private func validate() {
        guard let name = self.name, !name.isEmpty, !items.isEmpty else {
            isSaveButtonEnabled.accept(false)
            return
        }
        isSaveButtonEnabled.accept(true)
    }
    
    private func updateDataState() {
        if items.isEmpty {
            state.accept(.noData)
        } else {
            state.accept(.dataReady(nil))
        }
    }
}
