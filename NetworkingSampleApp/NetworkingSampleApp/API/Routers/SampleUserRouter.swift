//
//  SampleUserRouter.swift
//  networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation
import Networking

enum SampleUserRouter: Requestable {
    case users(page: Int)
    case user(userId: Int)
    case createUser(SampleUserRequest)
    case registerUser(SampleUserAuthRequest)
    case loginUser(SampleUserAuthRequest)

    var baseURL: URL {
        // this comes from a config - already force unwrapped
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://reqres.in/api")!
    }

    var path: String {
        switch self {
        case .users, .createUser:
            return "users"
        case let .user(userId):
            return "user/\(userId)"
        case .registerUser:
            return "register"
        case .loginUser:
            return "login"
        }
    }

    var urlParameters: [String: Any]? {
        switch self {
        case let .users(page):
            return ["page": page]
        default:
            return nil
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createUser, .registerUser, .loginUser:
            return .post
        default:
            return .get
        }
    }

    var dataType: RequestDataType? {
        switch self {
        case let .createUser(user):
            return .encodable(user)
        case let .registerUser(user), let .loginUser(user):
            return .encodable(user)
        default:
            return nil
        }
    }

    var isAuthenticationRequired: Bool {
        switch self {
        case .registerUser, .loginUser:
            return false
        case .createUser, .users, .user:
            return true
        }
    }
}
