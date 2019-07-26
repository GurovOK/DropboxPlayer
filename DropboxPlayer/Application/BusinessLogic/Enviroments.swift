//
//  Enviroments.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

class Envitoments {
    
    private struct Constants {
        static let enviromentsFileName = "Enviroments"
        static let enviromentsFileExtension = "plist"
        static let coreDataModelName = "Model"
    }
    
    private struct Keys {
        static let appKey = "DropboxAppKey"
        static let appSecret = "DropboxAppSecret"
    }
    
    let dropboxAppKey: String
    let dropboxAppSecret: String
    let coreDataModelName: String = Constants.coreDataModelName
    
    init() {
        guard let fileURL = Bundle.main.url(
            forResource: Constants.enviromentsFileName,
            withExtension: Constants.enviromentsFileExtension),
            let fileData = try? Data(contentsOf: fileURL) else {
                fatalError("Enviroments file not found")
        }
        let configurationFileName = "\(Constants.enviromentsFileName).\(Constants.enviromentsFileExtension)"
        guard let plistDict = try? PropertyListSerialization.propertyList(
            from: fileData,
            options: .mutableContainersAndLeaves,
            format: nil) as? [String: Any] else {
                fatalError("Unsupported \(configurationFileName) file format")
        }
        guard let dropboxAppKey = plistDict[Keys.appKey] as? String,
            !dropboxAppKey.isEmpty else {
                fatalError("Invalid \(Keys.appKey) value. Check \(configurationFileName) file")
        }
        guard let dropboxAppSecret = plistDict[Keys.appSecret] as? String,
            !dropboxAppSecret.isEmpty else {
                fatalError("Invalid \(Keys.appSecret) value. Check \(configurationFileName) file")
        }
        self.dropboxAppKey = dropboxAppKey
        self.dropboxAppSecret = dropboxAppSecret
    }
}

extension Envitoments: DropboxEnvitoments {}
