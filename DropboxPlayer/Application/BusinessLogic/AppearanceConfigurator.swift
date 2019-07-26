//
//  AppearanceConfigurator.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

struct AppearanceConfigurator {
    
    static func configure() {
        configureNavigationBar()
        UIButton.appearance().tintColor = .primary
        UITabBar.appearance().tintColor = .primary
    }
    
    private static func configureNavigationBar() {
        let appearance = UINavigationBar.appearance()
        appearance.tintColor = .primary
        appearance.titleTextAttributes = [.foregroundColor: UIColor.primary]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.primary,
                                               .font: UIFont.preferredFont(forTextStyle: .title1)]
    }
}
