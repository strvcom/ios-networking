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
        /// sample API host
        // swiftlint:disable:next force_unwrapping
        URL(string: SampleAPIConstants.userHost)!
    }

    var path: String {
        switch self {
        case .users, .createUser:
            return "users"
        case let .user(userId):
            return "user/\(userId)"
        case .registerUser:
            return "register"
        }
    }

    var urlParameters: [String: Any]? {
        switch self {
        case let .users(page):
            return ["page": page]
        case .createUser, .registerUser, .user:
            return nil
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createUser, .registerUser:
            return .post
        case .users, .user:
            return .get
        }
    }

    var dataType: RequestDataType? {
        switch self {
        case let .createUser(user):
            return .encodable(user)
        case let .registerUser(user):
            return .encodable(user)
        case .users, .user:
            return nil
        }
    }

    var isAuthenticationRequired: Bool {
        switch self {
        case .registerUser:
            return false
        case .createUser, .users, .user:
            return true
        }
    }
}
