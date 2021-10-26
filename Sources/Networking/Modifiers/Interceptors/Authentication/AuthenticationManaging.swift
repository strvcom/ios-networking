//
//  AuthenticationManaging.swift
//  Networking
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Authentication managing

/// Protocol defines basic behavior of authentication manager
public protocol AuthenticationManaging {
    /// Information whether API layer is ready to use authenticated communication
    var isAuthenticated: Bool { get }

    /// Authenticate to API service
    /// - Returns: Publisher streaming flag that authentication is done
    func authenticate() -> AnyPublisher<Void, AuthenticationError>
    /// Destroy any stored information related to authentication
    func revoke()
}
