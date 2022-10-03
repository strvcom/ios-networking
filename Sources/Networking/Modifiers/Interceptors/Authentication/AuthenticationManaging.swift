//
//  AuthenticationManaging.swift
//  Networking
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Authentication managing

/// A type that manages authentication with an API service using an OAuth protocol.
public protocol AuthenticationManaging: AuthenticationProviding {
    /// A Boolean flag indicating whether the API layer is ready to use authenticated communication.
    var isAuthenticated: Bool { get }

    /// Destroys any stored information related to authentication.
    func revoke()
    /// Stores authentication data from the API.
    func store(_ authenticationTokenData: AuthenticationTokenData)
}
