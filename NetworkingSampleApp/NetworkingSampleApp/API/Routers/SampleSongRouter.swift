//
//  SampleSongRouter.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 12.12.2022.
//

import Foundation
import Networking

/// Implementation of sample API router
enum SampleSongRouter: Requestable {
    case loginUser(user: SampleUserAuthRequest)
    case songs
    
    var baseURL: URL {
        /// sample API host
        // swiftlint:disable:next force_unwrapping
        return URL(string: SampleAPIConstants.songsHost)!
    }

    var path: String {
        switch self {
        case .loginUser:
            return "auth/authorize"
        case .songs:
            return "songs"
        }
    }

    var urlParameters: [String: Any]? {
        nil
    }

    var method: HTTPMethod {
        switch self {
        case .loginUser:
            return .post
        default:
            return .get
        }
    }

    var dataType: RequestDataType? {
        switch self {
        case let .loginUser(user):
            return .encodable(user)
        default:
            return nil
        }
    }

    var isAuthenticationRequired: Bool {
        switch self {
        case .songs:
            return true
        default:
            return false
        }
    }
}
