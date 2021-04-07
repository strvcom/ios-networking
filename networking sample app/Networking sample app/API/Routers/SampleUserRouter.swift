//
//  SampleUserRouter.swift
//  ios networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation
import Networking

enum SampleUserRouter: Requestable {
    
    case users
    case user(Int)
    case createUser(SampleUserRequest)
    case registerUser(SampleUserAuthRequest)
    case loginUser(SampleUserAuthRequest)
    
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
        case .registerUser, .loginUser, .users, .user:
            return false
        case .createUser:
            return true
        }
    }
}
