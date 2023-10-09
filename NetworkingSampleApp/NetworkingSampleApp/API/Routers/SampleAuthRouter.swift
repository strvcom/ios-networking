//
//  SampleAuthRouter.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 12.12.2022.
//

import Foundation
import Networking

/// Implementation of sample API router
enum SampleAuthRouter: Requestable {
    case loginUser(SampleUserAuthRequest)
    case refreshToken(SampleRefreshTokenRequest)
    case status
    
    var baseURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: SampleAPIConstants.authHost)!
    }

    var path: String {
        switch self {
        case .loginUser:
            "auth/authorize"
        case .refreshToken:
            "auth/refresh"
        case .status:
            "auth/status"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .loginUser, .refreshToken:
            .post
        default:
            .get
        }
    }

    var dataType: RequestDataType? {
        switch self {
        case let .loginUser(user):
             .encodable(user, hideFromLogs: true)
        case let .refreshToken(token):
             .encodable(token)
        default:
             nil
        }
    }

    var isAuthenticationRequired: Bool {
        switch self {
        case .status:
             true
        default:
             false
        }
    }
}
