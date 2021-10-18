//
//  AuthenticationManaging.swift
//  Networking
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines authentication managing

public protocol AuthenticationManaging {
    var isAuthenticated: Bool { get }

    func authenticate() -> AnyPublisher<Void, AuthenticationError>
    func revoke()
}
