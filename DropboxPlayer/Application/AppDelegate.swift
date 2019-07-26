//
//  AppDelegate.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var mainCoordinator: MainCoordinator?
    private let dependencies = AppDependencies(enviroments: Envitoments())

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppearanceConfigurator.configure()
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        let coordinator = MainCoordinator(window: window, appDependency: dependencies)
        coordinator.start()
        mainCoordinator = coordinator
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        dependencies.dropboxService.handle(open: url)
        return true
    }
}

