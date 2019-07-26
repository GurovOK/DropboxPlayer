//
//  ProfileViewController.swift
//  DropboxPlayer
//
//  Created by Oleg on 18/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift

class ProfileViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var logoutButton: UIButton! {
        didSet {
            logoutButton.setTitle("Выйти", for: .normal)
        }
    }
    @IBOutlet private weak var cloudSpaceInfoLabel: UILabel!
    @IBOutlet private weak var profileRequestIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var logoutIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private let viewModel: ProfileViewModel!
    private let disposeBag = DisposeBag()
    private let spaceFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter
    }()
    
    // MARK: - Init
    
    init(viewModel: ProfileViewModel) {
        
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindToViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.requestProfileInfo()
    }
    
    // MARK: - Private methods
    
    private func bindToViewModel() {
        viewModel
            .isLogoutInProgress
            .subscribe(onNext: { [weak self] inProgress in
                self?.logoutButton.isEnabled = !inProgress
                self?.logoutButton.titleLabel?.isHidden = inProgress
                if inProgress {
                    self?.logoutIndicator.startAnimating()
                } else {
                    self?.logoutIndicator.stopAnimating()
                }
        }).disposed(by: disposeBag)
        viewModel
            .state
            .subscribe(onNext: { [weak self] state in
            self?.handle(state: state)
        }).disposed(by: disposeBag)
    }
    
    private func handle(state: ProfileViewModel.State?) {
        guard let state = state else { return }
        profileRequestIndicator.stopAnimating()
        switch state {
        case .loading:
            profileRequestIndicator.startAnimating()
        case .dataReady(let profileInfo):
            guard let profileInfo = profileInfo else { return }
            userNameLabel.text = profileInfo.user.name
            emailLabel.text = profileInfo.user.email
            cloudSpaceInfoLabel.text = spaceString(from: profileInfo.spaceUsageInfo)
        case .error:
            showAlert(withTitle: "Что-то пошло не по плану".localized())
        case .noData:
            break
        }
    }
    
    private func spaceString(from spaceInfo: SpaceUsageInfo) -> String {
        let used = spaceFormatter.string(fromByteCount: Int64(spaceInfo.used))
        let available: String
        if let space = spaceInfo.allocated {
            available = spaceFormatter.string(fromByteCount: Int64(space))
        } else {
            available = "?"
        }
        return "\(used) / \(available)"
    }
    
    // MARK: - Actions
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        viewModel.logout()
    }
}
