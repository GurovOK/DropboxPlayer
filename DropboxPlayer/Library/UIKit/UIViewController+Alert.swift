//
//  UIViewController+Alert.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/06/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

extension UIViewController {
    
    typealias AlertButtonHandler = () -> Void
    typealias AlertButtonInfo = (title: String, handler: AlertButtonHandler?)
    
    func showAlert(withTitle title: String,
                   message: String? = nil,
                   confirmButtonTitle: String = "Ok".localized(),
                   confirmButtonHandler: AlertButtonHandler? = nil) {
        
        showAlert(withTitle: title,
                  message: message,
                  confirmButtonInfo: (confirmButtonTitle, confirmButtonHandler),
                  cancelButtonInfo: nil)
    }
    
    func showAlert(withTitle title: String,
                   message: String? = nil,
                   confirmButtonTitle: String = "Ok".localized(),
                   confirmButtonHandler: AlertButtonHandler? = nil,
                   cancelButtonTitle: String,
                   cancelButtonHandler: AlertButtonHandler? = nil) {
        
        showAlert(withTitle: title,
                  message: message,
                  confirmButtonInfo: (confirmButtonTitle, confirmButtonHandler),
                  cancelButtonInfo: (cancelButtonTitle, cancelButtonHandler))
    }
    
    func showRetryAlert(withTitle title: String = "Упс, что-то пошло не так".localized(),
                        confirmButtonTitle: String = "Попробовать снова".localized(),
                        cancelButtonTitle: String = "Отмена".localized(),
                        confirmButtonHandler: AlertButtonHandler? = nil) {
        showAlert(
            withTitle: title,
            confirmButtonTitle: confirmButtonTitle,
            confirmButtonHandler: confirmButtonHandler,
            cancelButtonTitle: cancelButtonTitle)
    }
    
    private func showAlert(withTitle title: String,
                           message: String? = nil,
                           confirmButtonInfo: AlertButtonInfo,
                           cancelButtonInfo: AlertButtonInfo?) {
        
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let confirmButton = UIAlertAction(title: confirmButtonInfo.title,
                                          style: .default,
                                          handler: { _ in
                                            confirmButtonInfo.handler?()
        })
        alertController.addAction(confirmButton)
        if let cancelButtonInfo = cancelButtonInfo {
            let cancelButton = UIAlertAction(title: cancelButtonInfo.title,
                                             style: .cancel,
                                             handler: { _ in
                                                cancelButtonInfo.handler?()
            })
            alertController.addAction(cancelButton)
        }
        present(alertController, animated: true, completion: nil)
    }
}
