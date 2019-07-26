//
//  PlaylistTableCell.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

class PlaylistTableCell: UITableViewCell {

    @IBOutlet private var playlistNameLabel: UILabel!
    
    func configure(with viewModel: PlaylistTableCellViewModel) {
        
        playlistNameLabel.text = viewModel.name
    }
}

struct PlaylistTableCellViewModel {
    
    let name: String
}
