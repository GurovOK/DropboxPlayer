//
//  AuthorizationViewController.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit
import RxSwift

class AuthorizationViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet private weak var signInButton: UIButton! {
        didSet {
            signInButton.setTitle("Войти".localized(), for: .normal)
        }
    }
    
    // MARK: - Properties
    
    private let viewModel: AuthorizationViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    init(viewModel: AuthorizationViewModel) {
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
    
    // MARK: - Private methods
    
    private func bindToViewModel() {
        viewModel
            .state
            .subscribe(onNext: { [weak self] state in
                self?.handle(state: state)
        }).disposed(by: disposeBag)
    }
    
    private func handle(state: AuthorizationViewModel.State?) {
        guard let state = state else { return }
        setLoadingStateActive(false)
        switch state {
        case .loading:
            setLoadingStateActive(true)
        case .error(let error):
            switch error {
            case .dropboxError:
                showAlert(withTitle: "Что-то пошло не так".localized())
            case .cancelled:
                break
            }
        case .dataReady, .noData:
            break
        }
    }
    
    private func setLoadingStateActive(_ active: Bool) {
        signInButton.titleLabel?.isHidden = !active
        signInButton.isEnabled = !active
    }
    
    // MARK: - Actions
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        viewModel.authorize()
    }
}
