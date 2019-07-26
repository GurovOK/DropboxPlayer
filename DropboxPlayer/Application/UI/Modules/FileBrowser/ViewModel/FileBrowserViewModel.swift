//
//  FileBrowserViewModel.swift
//  DropboxPlayer
//
//  Created by Oleg on 17/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol FileBrowserViewModelDelegate: class {
    
    func didSelectFolder(_ folder: Folder)
    func didSelectFiles(_ files: [AudioFile])
    func didRequestToClose()
}

protocol FileBrowserViewModel: class {
    
    typealias State = ViewModelState<Void, Error>
    
    var title: String? { get }
    var numberOfFiles: Int { get }
    var state: BehaviorRelay<State?> { get }
    var hasAudioFiles: BehaviorRelay<Bool> { get }
    var allFilesSelected: BehaviorRelay<Bool> { get }
    var updatedRowIndexPath: BehaviorRelay<IndexPath?> { get }
    
    func fileCellViewModel(at indexPath: IndexPath) -> FileCellViewModel?
    func selectFile(at indexPath: IndexPath)
    func selectAll()
    func deselectAll()
    func requestFileList()
    func close()
    func save()
}

class FileList {
    
    private(set) var selectedFiles: [AudioFile] = []
    
    func append(_ file: AudioFile) {
        
        guard !selectedFiles.contains(file) else { return }
        selectedFiles.append(file)
    }
    
    func remove(_ file: AudioFile) {
        
        guard let index = selectedFiles.firstIndex(of: file) else { return }
        selectedFiles.remove(at: index)
    }
    
    func contains(_ file: AudioFile) -> Bool {
        
        return selectedFiles.contains(file)
    }
}

class FileBrowserViewModelImplementation: FileBrowserViewModel {
    
    typealias Dependencies = HasDropboxService
    
    // MARK: - Properties
    
    weak var delegate: FileBrowserViewModelDelegate?
    let state = BehaviorRelay<State?>(value: nil)
    let updatedRowIndexPath = BehaviorRelay<IndexPath?>(value: nil)
    let hasAudioFiles = BehaviorRelay<Bool>(value: false)
    let allFilesSelected = BehaviorRelay<Bool>(value: false)
    var title: String? {
        return path
    }
    var numberOfFiles: Int {
        return fileTypes.count
    }
    
    private let dependencies: Dependencies
    private var dropboxService: DropboxService {
        return dependencies.dropboxService
    }
    private let path: String
    private let disposeBag = DisposeBag()
    private var fileTypes: [FileType] = []
    private let selectedFileList: FileList
    
    // MARK: - Init
    
    init(dependencies: Dependencies,
         path: String = "",
         selectedFileList: FileList) {
        
        self.path = path
        self.dependencies = dependencies
        self.selectedFileList = selectedFileList
    }
    
    // MARK: - Public methods
    
    func fileCellViewModel(at indexPath: IndexPath) -> FileCellViewModel? {
        guard let fileType = fileType(at: indexPath) else {
            return nil
        }
        var isSelected = false
        if case let .file(audioFile) = fileType {
            isSelected = selectedFileList.contains(audioFile)
        }
        return FileCellViewModelFactory.makeFileCellViewModel(with: fileType, isSelected: isSelected)
    }
    
    func selectFile(at indexPath: IndexPath) {
        guard let fileType = fileType(at: indexPath) else {
            return
        }
        switch fileType {
        case .file(let audioFile):
            if selectedFileList.selectedFiles.contains(audioFile) {
                selectedFileList.remove(audioFile)
            } else {
                selectedFileList.append(audioFile)
            }
            updatedRowIndexPath.accept(indexPath)
        case .folder(let folder):
            delegate?.didSelectFolder(folder)
        }
        checkFilesSelection()
    }
    
    func selectAll() {
        
        fileTypes.forEach {
            switch $0 {
            case .file(let file):
                if !selectedFileList.selectedFiles.contains(file) {
                    selectedFileList.append(file)
                }
            case .folder:
                break
            }
        }
        state.accept(.dataReady(nil))
        checkFilesSelection()
    }
    
    func deselectAll() {
        
        fileTypes.forEach {
            switch $0 {
            case .file(let file):
                if selectedFileList.selectedFiles.contains(file) {
                    selectedFileList.remove(file)
                }
            case .folder:
                break
            }
        }
        state.accept(.dataReady(nil))
        checkFilesSelection()
    }
    
    func requestFileList() {
        state.accept(.loading)
        guard dropboxService.isAuthorized else { return }
        dropboxService
            .requestFileList(withPath: path)
            .subscribe(onSuccess: { fileTypes in
                self.fileTypes = fileTypes.sorted(by: {
                    switch ($0, $1) {
                    case (.folder(let lhs), .file(let rhs)):
                        return lhs.name < rhs.name
                    case (.file(let lhs), .folder(let rhs)):
                        return lhs.name < rhs.name
                    case (.folder(let lhs), .folder(let rhs)):
                        return lhs.name < rhs.name
                    case (.file(let lhs), .file(let rhs)):
                        return lhs.name < rhs.name
                    }
                })
                if fileTypes.isEmpty {
                    self.state.accept(.noData)
                } else {
                    self.state.accept(.dataReady(nil))
                }
                let firstAudioFile = fileTypes.first(where: {
                    guard case .file = $0 else { return false }
                    return true
                })
                self.hasAudioFiles.accept(firstAudioFile != nil)
        }, onError: { error in
            self.state.accept(.error(error))
        }).disposed(by: disposeBag)
    }
    
    func close() {
        delegate?.didRequestToClose()
    }
    
    func save() {
        delegate?.didSelectFiles(selectedFileList.selectedFiles)
    }
    
    // MARK: - Private methods
    
    private func fileType(at indexPath: IndexPath) -> FileType? {
        guard indexPath.row >= 0, indexPath.row < numberOfFiles else {
            return nil
        }
        return fileTypes[indexPath.row]
    }
    
    private func checkFilesSelection() {
        let allFilesSelected = fileTypes.reduce(true) {
            switch $1 {
            case .folder:
                return $0
            case .file(let file):
                return $0 && self.selectedFileList.contains(file)
            }
        }
        self.allFilesSelected.accept(allFilesSelected)
    }
}
