//
//  FileType.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import SwiftyDropbox
import CoreServices

enum FileType {
    
    case folder(Folder), file(AudioFile)
}

extension FileType {
    
    init?(metadata: Files.Metadata) {
        switch metadata {
        case let file as Files.FileMetadata:
            let fileExtension = (file.name as NSString).pathExtension
            let fileUTI = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension,
                fileExtension as CFString,
                nil)
            if let fileUTI = fileUTI?.takeRetainedValue(),
                UTTypeConformsTo(fileUTI, kUTTypeAudio),
                let path = file.pathLower {
                self = .file(AudioFile(id: file.id,
                                       name: file.name,
                                       size: file.size,
                                       pathLower: path,
                                       pathDisplay: file.pathDisplay))
            } else {
                return nil
            }
        case let folder as Files.FolderMetadata:
            
            self = .folder(Folder(id: folder.id,
                                  name: folder.name,
                                  pathLower: folder.pathLower,
                                  pathDisplay: folder.pathDisplay))
        default:
            return nil
        }
    }
}
