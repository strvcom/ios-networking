//
//  KeychainAuthenticationCredentialsManager.swift
//
//
//  Created by Tomas Cejka on 07.10.2021.
//

import Combine
import Foundation

// MARK: - Keychain version for authentication by credentials
// stores & reads authentication token, credentials from keychain

open class KeychainAuthenticationCredentialsManager: RequestAuthorizing {
    public let refreshAuthenticationCredentialsManager: RefreshAuthenticationCredentialsManaging

    // MARK: Private properties
    private lazy var keychainManager = KeychainManager()

    // MARK: Init

    public init(refreshAuthenticationCredentialsManager: RefreshAuthenticationCredentialsManaging) {
        self.refreshAuthenticationCredentialsManager = refreshAuthenticationCredentialsManager
    }
}

// MARK: - AuthenticationCredentialsManaging methods

extension KeychainAuthenticationCredentialsManager: AuthenticationCredentialsManaging {
    public var login: String? {
        keychainManager.login
    }

    public var password: String? {
        keychainManager.password
    }

    public var authenticationToken: String? {
        keychainManager.credentialsAuthenticationToken
    }

    public func store(_ authenticationToken: String) {
        keychainManager.setString(
            value: authenticationToken,
            key: .credentialsAuthenticationToken
        )
    }

    public func store(login: String?, password: String?) {
        keychainManager.setString(
            value: login,
            key: .login
        )

        keychainManager.setString(
            value: password,
            key: .password
        )
    }

    public func revoke() {
        // delete all keys
        KeychainKey.credentialsKeys.forEach {
            keychainManager.remove(key: $0)
        }
    }
}
