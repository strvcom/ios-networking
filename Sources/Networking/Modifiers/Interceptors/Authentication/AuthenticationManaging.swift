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
public protocol AuthenticationManaging: AuthenticationProviding {
    /// Information whether API layer is ready to use authenticated communication
    var isAuthenticated: Bool { get }

    var authenticationToken: String? { get }
    var authenticationTokenExpirationDate: Date? { get }
    var refreshToken: String? { get }
    var refreshTokenExpirationDate: Date? { get }

    /// Destroy any stored information related to authentication
    func revoke()
    // allows set authentication data from outside
    func store(_ authenticationTokenData: AuthenticationTokenData)
}
