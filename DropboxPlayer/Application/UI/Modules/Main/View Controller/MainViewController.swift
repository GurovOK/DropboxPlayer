//
//  MainViewController.swift
//  DropboxPlayer
//
//  Created by Oleg on 12/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: - Properties
    
    var items: [MainControllerItem] = [] {
        didSet {
            internalTabbarController.viewControllers = items.map {
                $0.controller
            }
        }
    }
    private let internalTabbarController = UITabBarController()
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarViewController()
    }
    
    // MARK: - Public methods
    
    func select(tab: MainControllerTab) {
        guard let controller = items.first(where: { $0.tab == tab} )?.controller,
            let index = internalTabbarController.viewControllers?.firstIndex(where: { $0 == controller} ) else {
            return
        }
        internalTabbarController.selectedIndex = index
    }
    
    // MARK: - Private methods
    
    private func configureTabBarViewController() {
        internalTabbarController.willMove(toParent: self)
        addChild(internalTabbarController)
        let contentView: UIView = internalTabbarController.view
        view.addSubview(contentView)
        internalTabbarController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        internalTabbarController.didMove(toParent: self)
        internalTabbarController.additionalSafeAreaInsets.bottom = -20
    }
}
