//
//  SampleUserRouter.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation
import Networking

/// Implementation of sample API router
enum SampleUserRouter: Requestable {
    case users(page: Int)
    case user(userId: Int)
    case createUser(user: SampleUserRequest)
    case registerUser(user: SampleUserAuthRequest)
    
    var baseURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: SampleAPIConstants.userHost)!
    }

    var path: String {
        switch self {
        case .users, .createUser:
            "users"
        case let .user(userId):
            "user/\(userId)"
        case .registerUser:
            "register"
        }
    }

    var urlParameters: [String: Any]? {
        switch self {
        case let .users(page):
            ["page": page]
        case .createUser, .registerUser, .user:
            nil
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createUser, .registerUser:
            .post
        case .users, .user:
            .get
        }
    }

    var dataType: RequestDataType? {
        switch self {
        case let .createUser(user):
            .encodable(user)
        case let .registerUser(user):
            .encodable(user)
        case .users, .user:
            nil
        }
    }

    var isAuthenticationRequired: Bool {
        switch self {
        case .registerUser:
            false
        case .createUser, .users, .user:
            true
        }
    }
}
