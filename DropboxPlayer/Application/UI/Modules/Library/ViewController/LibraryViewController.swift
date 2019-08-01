//
//  LibraryViewController.swift
//  DropboxPlayer
//
//  Created by Oleg on 14/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol LibraryViewControllerDelegate: class {
    
    func libraryViewController(_ viewController: LibraryViewController,
                               didRequestToOpenPlayerWithTransitionController controller: PlayerTransitionController)
}

class LibraryViewController: UIViewController {
    
    private struct Constants {
        static let presentationPercentThreshold: CGFloat = 0.5
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var refreshControl = UIRefreshControl()
    private let playerView: MiniPlayerView = MiniPlayerView.fromNib()
    
    // MARK: - Properties
    
    weak var delegate: LibraryViewControllerDelegate?
    private var addPlaylistButton: UIBarButtonItem?
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.text = "Добавьте новый плейлист".localized()
        return label
    }()
    private var errorStateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Упс, что-то пошло не так. Попробуйте обновить список.".localized()
        return label
    }()
    
    private var playerCenterXConstraint: NSLayoutConstraint?
    
    private let viewModel: LibraryViewModel
    private let disposeBag = DisposeBag()
    private var transitionController: PlayerTransitionController?
    
    // MARK: - Init
    
    init(with viewModel: LibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
        configureEmptyView()
        configureRefreshControl()
        configureMiniPlayerView()
        bindToViewModel()
        setupPanContentRecognizer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.requestPlaylists()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updataTableInsets()
    }
    
    // MARK: - Private methods
    
    private func bindToViewModel() {
        navigationItem.title = viewModel.title
        viewModel
            .state
            .subscribe(onNext: { [weak self] state in
                
                self?.handle(state)
            }).disposed(by: disposeBag)
        viewModel
            .miniPlayerVisible
            .subscribe(onNext: { [weak self] visible in
                
                self?.setPlayerVisible(visible, animated: true)
            }).disposed(by: disposeBag)
        playerView.configure(with: viewModel.miniPlayerViewModel)
    }
    
    private func handle(_ state: LibraryViewModel.State?) {
        guard let state = state else { return }
        tableView.backgroundView = nil
        activityIndicator.stopAnimating()
        addPlaylistButton?.isEnabled = false
        refreshControl.endRefreshing()
        switch state {
        case .dataReady:
            addPlaylistButton?.isEnabled = true
            tableView.reloadData()
        case .noData:
            addPlaylistButton?.isEnabled = true
            tableView.backgroundView = emptyStateLabel
            tableView.reloadData()
        case .loading:
            if !refreshControl.isRefreshing {
                activityIndicator.startAnimating()
            }
        case .error:
            tableView.backgroundView = errorStateLabel
            showRetryAlert() { [weak self] in
                self?.viewModel.requestPlaylists()
            }
        }
    }
    
    private func setPlayerVisible(_ visible: Bool, animated: Bool) {
        updataTableInsets()
        let newValue = visible ? 0 : view.bounds.width
        guard playerCenterXConstraint?.constant != newValue else {
            return
        }
        playerCenterXConstraint?.constant = newValue
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func updataTableInsets() {
        var bottomInset = view.safeAreaInsets.bottom
        if viewModel.miniPlayerVisible.value {
            bottomInset += playerView.frame.height
        }
        tableView.contentInset.bottom = bottomInset
    }
    
    private func setupPanContentRecognizer() {
        let panRecognizer = UIPanGestureRecognizer(target: self,
                                                   action: #selector(handlePanGesture(_:)))
        playerView.addGestureRecognizer(panRecognizer)
    }
    
    // MARK: - Actions
    
    @objc private func addNewPlaylist() {
        viewModel.addNewPlaylist()
    }
    
    @objc private func addNewPlaylisstButtonTapped() {
        addNewPlaylist()
    }
    
    @objc private func refreshData() {
        viewModel.requestPlaylists()
    }
}

// MARK: - Configuration
extension LibraryViewController {
    
    private func configureRefreshControl() {
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self,
                                 action: #selector(refreshData),
                                 for: .valueChanged)
    }
    
    private func configureEmptyView() {
        let tapRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(addNewPlaylist))
        emptyStateLabel.addGestureRecognizer(tapRecognizer)
    }
    
    private func configureTable() {
        tableView.tableFooterView = UIView()
        PlaylistTableCell.registerNib(in: tableView)
    }
    
    private func configureMiniPlayerView() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)
        let centerXConstraint = playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        playerCenterXConstraint = centerXConstraint
        NSLayoutConstraint.activate([
            centerXConstraint,
            playerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            playerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor)])
        setPlayerVisible(false, animated: false)
    }
}

extension LibraryViewController {
    
    func makeRightBarButtonItems() -> [UIBarButtonItem] {
        let addPlaylistButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewPlaylisstButtonTapped))
        self.addPlaylistButton = addPlaylistButton
        return [addPlaylistButton]
    }
}

// MARK: - UITableViewDelegate
extension LibraryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectPlaylist(at: indexPath)
    }
}

// MARK: - UITableViewDataSource
extension LibraryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfPlaylists
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistTableCell.reuseIndntifier,
                                                 for: indexPath)
        if let cell = cell as? PlaylistTableCell,
            let cellViewModel = viewModel.playlistCellViewModel(at: indexPath) {
            cell.configure(with: cellViewModel)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actions = [
            UIContextualAction(
                style: .destructive,
                title: "Удалить".localized()) { [weak self] (_, _, completion) in
                    self?.showAlert(
                        withTitle: "Удалить плейлист?".localized(),
                        confirmButtonTitle: "Удалить".localized(),
                        confirmButtonHandler: { [weak self] in
                            self?.viewModel.deletePlaylist(at: indexPath)
                            completion(true)
                        },
                        cancelButtonTitle: "Отмена".localized(),
                        cancelButtonHandler: {
                            completion(false)
                    })
            },
            UIContextualAction(
                style: .normal,
                title: "Редактировать".localized()) { [weak self] (_, _, completion) in
                    self?.viewModel.editPlaylist(at: indexPath)
                    completion(true)
            }]
        return UISwipeActionsConfiguration(actions: actions)
    }
}

extension LibraryViewController {
    
    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        
        guard let delegate = self.delegate else { return }
        let location = recognizer.location(in: view)
        
        let contentHeight = view.bounds.height
        let movementPercent = 1 - location.y / contentHeight
        switch recognizer.state {
        case .began:
            let transitionController = PlayerTransitionController()
            transitionController.hasStarted = true
            delegate.libraryViewController(self,
                                           didRequestToOpenPlayerWithTransitionController: transitionController)
            self.transitionController = transitionController
        case .changed:
            if transitionController?.hasStarted == true {
                transitionController?.shouldFinish = movementPercent > Constants.presentationPercentThreshold
                transitionController?.update(movementPercent)
            }
        case .cancelled, .failed:
            transitionController?.hasStarted = false
            transitionController?.cancel()
        case .ended:
            transitionController?.hasStarted = false
            if recognizer.velocity(in: view).y > -2000 || transitionController?.shouldFinish == true {
                transitionController?.finish()
            } else {
                transitionController?.cancel()
            }
            transitionController = nil
        case .possible:
            break
        @unknown default:
            break
        }
    }
}
