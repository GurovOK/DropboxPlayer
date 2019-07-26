//
//  DropboxServiceError.swift
//  DropboxPlayer
//
//  Created by Oleg on 20/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import Foundation
import SwiftyDropbox

enum DropboxServiceError: Error {
    case unauthorizedClient, accessDenied, unsupportedResponseType
    case invalidScope, serverError, temporarilyUnavailable
    case inconsistentState, unknown, badInputError
    case rateLimitError, httpError, authError
    case accessError, routeError, clientError(Error?)
    case urlObtainingError
}

extension CallError {
    
    var dropboxServiceError: DropboxServiceError {
        switch self {
        case .internalServerError:
            return .serverError
        case .badInputError:
            return .serverError
        case .rateLimitError:
            return .rateLimitError
        case .httpError:
            return .httpError
        case .authError:
            return .unauthorizedClient
        case .accessError:
            return .accessError
        case .routeError:
            return .routeError
        case .clientError(let error):
            return .clientError(error)
        }
    }
}

extension OAuth2Error {
    
    var dropboxServiceError: DropboxServiceError {
        switch self {
        case .unauthorizedClient:
            return .unauthorizedClient
        case .accessDenied:
            return .accessDenied
        case .unsupportedResponseType:
            return .unsupportedResponseType
        case .invalidScope:
            return .invalidScope
        case .serverError:
            return .serverError
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        case .inconsistentState:
            return .inconsistentState
        case .unknown:
            return .unknown
        }
    }
}
