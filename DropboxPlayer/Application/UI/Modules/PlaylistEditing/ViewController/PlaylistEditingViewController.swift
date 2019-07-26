//
//  PlaylistEditingViewController.swift
//  DropboxPlayer
//
//  Created by Oleg on 15/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift

class PlaylistEditingViewController: UIViewController {
    
    private struct Constants {
        
        static let estimatedRowHeight: CGFloat = 100
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Properties
    
    private let editNameView: PlaylistNameEditView = PlaylistNameEditView.fromNib()
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .textPrimary
        label.isUserInteractionEnabled = true
        label.text = "Добавить треки".localized()
        return label
    }()
    
    private let viewModel: PlaylistEditingViewModel!
    private let disposeBag = DisposeBag()
    private var saveButton: UIBarButtonItem?
    
    // MARK: - Init
    
    init(viewModel: PlaylistEditingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureEmptyView()
        bindToViewModel()
    }
    
    // MARK: - Private methods
    
    private func configureEmptyView() {
        let tapRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(addFilesButtonTapped))
        emptyStateLabel.addGestureRecognizer(tapRecognizer)
    }
    
    private func bindToViewModel() {
        editNameView.name = viewModel.name
        viewModel
            .state
            .subscribe(onNext: { [weak self] state in
                
                self?.handle(state: state)
            }).disposed(by: disposeBag)
        viewModel
            .isSaveButtonEnabled
            .subscribe(onNext: { [weak self] isAvailable in
                
                self?.updateSaveButton()
            }).disposed(by: disposeBag)
    }
    
    private func handle(state: PlaylistEditingViewModel.State?) {
        guard let state = state else { return }
        
        updateSaveButton()
        tableView.backgroundView = nil
        switch state {
        case .dataReady:
            tableView.reloadData()
        case .noData:
            tableView.reloadData()
            tableView.backgroundView = emptyStateLabel
        case .error, .loading:
            break
        }
    }
    
    private func updateSaveButton() {
        saveButton?.isEnabled = viewModel.isSaveButtonEnabled.value
    }
    
    private func configureTableView() {
        FileTableCell.registerNib(in: tableView)
        tableView.isEditing = true
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = editNameView
        tableView.tableFooterView = UIView()
        
        editNameView.translatesAutoresizingMaskIntoConstraints = false
        editNameView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        editNameView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        editNameView.valueChangedHandler = { [unowned self] value in
            self.viewModel.changePlaylistName(value)
        }
    }
    
    // MARK: - Actions
    
    @objc private func addFilesButtonTapped() {
        viewModel.addFiles()
    }
    
    @objc private func cancelButtonTapped() {
        viewModel.cancel()
    }
    
    @objc private func saveButtonTapped() {
        viewModel.save()
    }
}

extension PlaylistEditingViewController {
    
    func makeLeftBarButtonItems() -> [UIBarButtonItem] {
        return [UIBarButtonItem(barButtonSystemItem: .cancel,
                                target: self,
                                action: #selector(cancelButtonTapped))]
    }
    
    func makeRightBarButtonItems() -> [UIBarButtonItem] {
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                         target: self,
                                         action: #selector(saveButtonTapped))
        self.saveButton = saveButton
        return [
            saveButton,
            UIBarButtonItem(barButtonSystemItem: .add,
                            target: self,
                            action: #selector(addFilesButtonTapped))]
    }
}

extension PlaylistEditingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
        case .delete:
            viewModel.deleteFile(at: indexPath)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView,
                   moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {
        viewModel.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
}

extension PlaylistEditingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfFiles
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FileTableCell.reuseIndntifier,
                                                 for: indexPath)
        if let cell = cell as? FileTableCell,
            let cellViewModel = viewModel.fileCellViewModel(at: indexPath) {
            cell.configure(with: cellViewModel)
        }
        return cell
    }
}
