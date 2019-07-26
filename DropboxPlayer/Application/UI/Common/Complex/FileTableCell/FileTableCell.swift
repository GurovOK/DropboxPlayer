//
//  FileTableCell.swift
//  DropboxPlayer
//
//  Created by Oleg on 22/03/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

class FileTableCell: UITableViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var fileNameLabel: UILabel!
    
    func configure(with viewModel: FileCellViewModel) {
        
        fileNameLabel.text = viewModel.fileName
        iconImageView.image = UIImage(named: viewModel.iconName)
        accessoryType = viewModel.isSelected ? .checkmark : .none
    }
}

struct FileCellViewModel {
    
    let iconName: String
    let fileName: String?
    let isSelected: Bool
}

struct FileCellViewModelFactory {
    
    static func makeFileCellViewModel(
        with fileType: FileType,
        isSelected: Bool = false) -> FileCellViewModel {
        
        let fileName: String
        switch fileType {
        case .file(let audioFile):
            fileName = audioFile.name
        case .folder(let folder):
            fileName = folder.name
        }
        return FileCellViewModel(iconName: fileType.iconName,
                                 fileName: fileName,
                                 isSelected: isSelected)
    }
}

private extension FileType {
    
    var iconName: String {
        switch self {
        case .file:
            return "audioFileIcon"
        case .folder:
            return "folderIcon"
        }
    }
}
