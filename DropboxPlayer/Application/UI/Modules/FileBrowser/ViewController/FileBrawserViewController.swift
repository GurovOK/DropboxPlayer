//
//  FileBrawserViewController.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift

class FileBrawserViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var refreshControl = UIRefreshControl()
    private var errorStateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .textPrimary
        label.text = "Упс, что-то пошло не так. Попробуйте обновить список.".localized()
        return label
    }()
    private var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .textPrimary
        label.text = "Аудио файлов не нашлось\n¯\\_(ツ)_/¯".localized()
        return label
    }()
    private var selectAllButton: UIBarButtonItem?
    
    // MARK: - Properties
    
    private let viewModel: FileBrowserViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(viewModel: FileBrowserViewModel) {
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
        configureRefreshControl()
        bindToViewModel()
        viewModel.requestFileList()
    }
    
    // MARK: - Private methods
    
    private func configureTableView() {
        FileTableCell.registerNib(in: tableView)
        tableView.tableFooterView = UIView()
    }
    
    private func configureRefreshControl() {
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    private func bindToViewModel() {
        title = viewModel.title
        viewModel
            .state
            .subscribe(onNext: { [weak self] state in
                
                self?.handle(state)
            }).disposed(by: disposeBag)
        viewModel
            .updatedRowIndexPath
            .subscribe(onNext: { [weak self] indexPath in
                
                guard let indexPath = indexPath else { return }
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }).disposed(by: disposeBag)
        viewModel
            .allFilesSelected
            .subscribe(onNext: { [weak self] allSelected in
           
                guard let selectAllButton = self?.selectAllButton else { return }
                selectAllButton.customView = self?.makeAllFilesEditingButton()
        }).disposed(by: disposeBag)
        viewModel
            .hasAudioFiles
            .subscribe(onNext: { [weak self] hasAudioFiles in
                
                self?.selectAllButton?.isEnabled = hasAudioFiles
            }).disposed(by: disposeBag)
    }
    
    private func handle(_ state: FileBrowserViewModel.State?) {
        guard let state = state else { return }
        tableView.backgroundView = nil
        activityIndicator.stopAnimating()
        switch state {
        case .dataReady:
            tableView.reloadData()
        case .error:
            tableView.backgroundView = errorStateLabel
            showRetryAlert() { [weak self] in
                self?.viewModel.requestFileList()
            }
        case .loading:
            if !refreshControl.isRefreshing {
                activityIndicator.startAnimating()
            }
        case .noData:
            tableView.backgroundView = emptyStateLabel
        }
        refreshControl.endRefreshing()
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        viewModel.close()
    }
    
    @objc private func addTracksButtonTapped() {
        viewModel.save()
    }
    
    @objc private func selectAllButtonTapped() {
        if viewModel.allFilesSelected.value {
            viewModel.deselectAll()
        } else {
            viewModel.selectAll()
        }
    }
    
    @objc private func refreshData() {
        viewModel.requestFileList()
    }
}

extension FileBrawserViewController {
    
    func makeLeftBarButtonItems() -> [UIBarButtonItem] {
        return [UIBarButtonItem(title: "Отмена".localized(),
                                style: .plain,
                                target: self,
                                action: #selector(cancelButtonTapped))]
    }
    
    func makeRightBarButtonItems() -> [UIBarButtonItem] {
        let selectAllButton = UIBarButtonItem(customView: makeAllFilesEditingButton())
        self.selectAllButton = selectAllButton
        return [UIBarButtonItem(title: "Добавить".localized(),
                                style: .plain,
                                target: self,
                                action: #selector(addTracksButtonTapped)),
                selectAllButton]
    }
    
    private func makeAllFilesEditingButton() -> UIButton {
        let button = UIButton(type: .custom)
        if viewModel.allFilesSelected.value {
            button.setTitle("Отменить выбор".localized(), for: .normal)
        } else {
            button.setTitle("Выбрать все".localized(), for: .normal)
        }
        button.setTitleColor(.primary, for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        button.isEnabled = viewModel.hasAudioFiles.value
        button.addTarget(self, action: #selector(selectAllButtonTapped), for: .touchUpInside)
        return button
    }
}

// MARK: - UITableViewDataSource
extension FileBrawserViewController: UITableViewDataSource {
    
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

// MARK: - UITableViewDelegate
extension FileBrawserViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectFile(at: indexPath)
    }
}
