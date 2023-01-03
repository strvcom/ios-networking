//
//  SampleSongRouter.swift
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
        /// sample API host
        // swiftlint:disable:next force_unwrapping
        return URL(string: SampleAPIConstants.songsHost)!
    }

    var path: String {
        switch self {
        case .loginUser:
            return "auth/authorize"
        case .refreshToken:
            return "auth/refresh"
        case .status:
            return "auth/status"
        }
    }

    var urlParameters: [String: Any]? {
        nil
    }

    var method: HTTPMethod {
        switch self {
        case .loginUser, .refreshToken:
            return .post
        default:
            return .get
        }
    }

    var dataType: RequestDataType? {
        switch self {
        case let .loginUser(user):
            return .encodable(user)
        case let .refreshToken(token):
            return .encodable(token)
        default:
            return nil
        }
    }

    var isAuthenticationRequired: Bool {
        switch self {
        case .status, .refreshToken:
            return true
        default:
            return false
        }
    }
    
    var isRefreshTokenRequest: Bool {
        switch self {
        case .refreshToken:
            return true
        default:
            return false
        }
    }
}
