//
//  KeychainAuthenticationTokenManager.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Combine
import Foundation
import KeychainSwift

open class KeychainAuthenticationTokenManager: AuthenticationProviding {
    // MARK: Keychain keys
    enum KeychainKey: String, CaseIterable {
        case authenticationToken = "com.strv.networking.authenticationToken"
        case authenticationTokenExpirationDate = "com.strv.networking.authenticationTokenExpirationDate"
        case refreshToken = "com.strv.networking.refreshToken"
        case refreshTokenExpirationDate = "com.strv.networking.refreshTokenExpirationDate"
    }

    // MARK: Public properties
    public private(set) var authenticationToken: String?
    public private(set) var authenticationTokenExpirationDate: Date?
    public private(set) var refreshToken: String?
    public private(set) var refreshTokenExpirationDate: Date?

    public let refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging

    // MARK: Private properties
    private lazy var keychain = KeychainSwift()

    // MARK: Init

    public init(refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging) {
        self.refreshAuthenticationTokenManager = refreshAuthenticationTokenManager
    }
}

// MARK: - AuthenticationTokenManaging methods

extension KeychainAuthenticationTokenManager: AuthenticationTokenManaging {
    public func store(_ authenticationTokenData: AuthenticationTokenData) {
        setString(
            value: authenticationTokenData.authenticationToken,
            key: .authenticationToken
        )
        setString(
            value: authenticationTokenData.refreshToken,
            key: .refreshToken
        )
        setString(
            value: authenticationTokenData.refreshToken,
            key: .refreshToken
        )
        setString(
            value: authenticationTokenData.refreshToken,
            key: .refreshToken
        )
    }

    public func revoke() {
        // delete all keys
        KeychainKey.allCases.forEach {
            keychain.delete($0.rawValue)
        }
    }
}

// MARK: - Private helper methods

private extension KeychainAuthenticationTokenManager {
    func setString(value: String?, key: KeychainKey) {
        guard let value = value else {
            remove(key: key)
            return
        }
        keychain.set(value, forKey: key.rawValue)
    }

    func string(key: KeychainKey) -> String? {
        keychain.get(key.rawValue)
    }

    func remove(key: KeychainKey) {
        keychain.delete(key.rawValue)
    }
}
