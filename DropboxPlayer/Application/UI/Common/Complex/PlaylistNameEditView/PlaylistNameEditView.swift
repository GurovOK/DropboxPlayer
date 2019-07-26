//
//  PlaylistNameEditView.swift
//  DropboxPlayer
//
//  Created by Oleg on 16/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

class PlaylistNameEditView: UIView {

    typealias PlaylistNameValueChanged = ((String?) -> Void)
    
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.text = title
        }
    }
    @IBOutlet private weak var textField: UITextField!
    
    var valueChangedHandler: PlaylistNameValueChanged?
    
    var title: String? = "Название:".localized() {
        didSet {
            titleLabel.text = title
        }
    }
    var name: String? {
        get {
            return textField.text
        }
        set {
            textField.text = newValue
        }
    }
    var placeholder: String? {
        didSet {
            textField.placeholder = placeholder
        }
    }
    
    @IBAction func textFieldEditingChanged(_ sender: Any) {
        valueChangedHandler?(textField.text)
    }
}
