//
//  ViewModelState.swift
//  DropboxPlayer
//
//  Created by Oleg on 18/04/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation

enum ViewModelState<Data, E> where E: Error {
    case dataReady(Data?)
    case loading
    case error(E)
    case noData
}
