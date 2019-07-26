//
//  FileBrowserCoordinator.swift
//  DropboxPlayer
//
//  Created by Oleg on 12/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

protocol FileBrowserCoordinatorDelegate: class {
    
    func didSelectFiles(_ files: [AudioFile])
}

class FileBrowserCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    weak var delegate: FileBrowserCoordinatorDelegate?
    var childCoordinators: [BaseCoordinator] = []
    var onDidFinish: (() -> Void)?
    
    private let presentationController: UIViewController
    private let appDependency: AppDependencies
    private var onDidSelectFolder: ((Folder) -> Void)?
    
    // MARK: - Init
    
    init(presentationController: UIViewController,
         appDependency: AppDependencies) {
        
        self.presentationController = presentationController
        self.appDependency = appDependency
    }
    
    // MARK: - Public methods
    
    func start() {
        let fileList = FileList()
        let viewModel = FileBrowserViewModelImplementation(dependencies: appDependency,
                                                           selectedFileList: fileList)
        viewModel.delegate = self
        let browserController = FileBrawserViewController(viewModel: viewModel)
        browserController.navigationItem.leftBarButtonItems = browserController.makeLeftBarButtonItems()
        browserController.navigationItem.rightBarButtonItems = browserController.makeRightBarButtonItems()
        browserController.navigationItem.largeTitleDisplayMode = .never
        let navigationController = UINavigationController(rootViewController: browserController)
        navigationController.navigationBar.prefersLargeTitles = true
        browserController.tabBarItem.image = #imageLiteral(resourceName: "fileBrowserIcon.pdf")
        presentationController.present(navigationController, animated: true, completion: nil)
        onDidSelectFolder = { [weak self] folder in
            
            self?.searchFiles(in: folder, with: fileList)
        }
    }
    
    // MARK: - Private methods
    
    private func searchFiles(in folder: Folder, with fileList: FileList) {
        guard let path = folder.pathLower,
            let navigationController = presentationController.presentedViewController as? UINavigationController else { return }
        let viewModel = FileBrowserViewModelImplementation(dependencies: appDependency,
                                                           path: path,
                                                           selectedFileList: fileList)
        viewModel.delegate = self
        let browserController = FileBrawserViewController(viewModel: viewModel)
        browserController.navigationItem.rightBarButtonItems = browserController.makeRightBarButtonItems()
        browserController.navigationItem.largeTitleDisplayMode = .always
        navigationController.pushViewController(browserController, animated: true)
    }
}

// MARK: - FileBrowserViewModelDelegate
extension FileBrowserCoordinator: FileBrowserViewModelDelegate {
    
    func didSelectFiles(_ files: [AudioFile]) {
        delegate?.didSelectFiles(files)
        presentationController.dismiss(animated: true) { [weak self] in
            self?.onDidFinish?()
        }
    }
    
    func didSelectFolder(_ folder: Folder) {
        onDidSelectFolder?(folder)
    }
    
    func didRequestToClose() {
        presentationController.dismiss(animated: true) { [weak self] in
            self?.onDidFinish?()
        }
    }
}
