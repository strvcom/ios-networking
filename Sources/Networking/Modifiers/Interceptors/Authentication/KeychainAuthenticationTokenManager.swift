//
//  KeychainAuthenticationTokenManager.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Combine
import Foundation

// MARK: - Keychain version for authentication token managing
// stores & reads authentication token data from keychain

open class KeychainAuthenticationTokenManager: AuthorizingRequest {
    public let refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging

    // MARK: Private properties
    private lazy var keychainManager = KeychainManager()

    // MARK: Init

    public init(refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging) {
        self.refreshAuthenticationTokenManager = refreshAuthenticationTokenManager
    }
}

// MARK: - AuthenticationTokenManaging methods

extension KeychainAuthenticationTokenManager: AuthenticationTokenManaging {
    public var authenticationToken: String? {
        keychainManager.authenticationToken
    }

    public var authenticationTokenExpirationDate: Date? {
        keychainManager.authenticationTokenExpirationDate
    }

    public var refreshToken: String? {
        keychainManager.refreshToken
    }

    public var refreshTokenExpirationDate: Date? {
        keychainManager.refreshTokenExpirationDate
    }

    public func store(_ authenticationTokenData: AuthenticationTokenData) {
        keychainManager.setString(
            value: authenticationTokenData.authenticationToken,
            key: .authenticationToken
        )

        keychainManager.setDate(
            value: authenticationTokenData.authenticationTokenExpirationDate,
            key: .authenticationTokenExpirationDate
        )

        keychainManager.setString(
            value: authenticationTokenData.refreshToken,
            key: .refreshToken
        )

        keychainManager.setDate(
            value: authenticationTokenData.refreshTokenExpirationDate,
            key: .refreshTokenExpirationDate
        )
    }

    public func revoke() {
        // delete all keys
        KeychainKey.refreshTokenKeys.forEach {
            keychainManager.remove(key: $0)
        }
    }
}
