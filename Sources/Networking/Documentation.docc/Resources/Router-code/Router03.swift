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
}
