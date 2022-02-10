//
//  ExampleRouter.swift
//
//
//  Created by Martin Vidovic on 10.02.2022.
//

import Networking

enum ExampleRouter: Requestable {
    case users(page: Int)
    case user(userId: Int)
    case createUser(SampleUserRequest)

    var baseURL: URL {
        URL(string: "https://xxxxx/api")!
    }

    var path: String {
        switch self {
        case .users, .createUser:
            return "users"
        case let .user(userId):
            return "user/\(userId)"
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

    var headers: [String: String]? {
        nil
    }
}
