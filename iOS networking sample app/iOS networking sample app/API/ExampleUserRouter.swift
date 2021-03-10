//
//  ExampleUserRouter.swift
//  STRV_template
//
//  Created by Tomas Cejka on 10.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import ios_networking

struct ExampleUserRequest: Encodable {
    let name: String
    let job: String
}

struct ExampleUserAuthRequest: Encodable {
    let email: String?
    let password: String?
}

struct ExampleUserAuthResponse: Decodable {
    let token: String
}

enum ExampleUserRouter: Requestable {
    
    case users
    case user(Int)
    case createUser(ExampleUserRequest)
    case registerUser(ExampleUserAuthRequest)
    case loginUser(ExampleUserAuthRequest)
    
    var baseURL: URL {
        // this comes from a config - already force unwrapped
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://reqres.in")!
    }

    var path: String {
        switch self {
        case .users, .createUser:
            return "api/users"
        case .user(let id):
            return "api/user/\(id)"
        case .registerUser:
            return "api/register"
        case .loginUser:
            return "api/login"
        }
    }
    
    var urlParameters: [String: Any]? {
        switch self {
        case .users:
            return ["page": 2]
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
        case .createUser(let user):
            return .encodable(user)
        case .registerUser(let user), .loginUser(let user):
            return .encodable(user)
        default:
            return nil
        }
    }
    
    var authenticated: Bool {
        switch self {
        case .registerUser, .loginUser, .users:
            return false
        default:
            return true
        }
    }
}
