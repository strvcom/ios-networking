//
//  AuthenticationTokenData.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Foundation

// MARK: - Authentication token data definition

/// A type that holds typical values required for OAuth authentication.
public protocol AuthenticationTokenData {
    var authenticationToken: String { get }
    var authenticationTokenExpirationDate: Date? { get }
    var refreshToken: String? { get }
    var refreshTokenExpirationDate: Date? { get }
}
