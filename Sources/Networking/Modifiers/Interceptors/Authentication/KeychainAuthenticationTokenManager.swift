//
//  KeychainAuthenticationTokenManager.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Combine
import Foundation
import KeychainSwift

// MARK: - Keychain version for authentication token managing
// stores & reads authentication token data from keychain

open class KeychainAuthenticationTokenManager: AuthenticationProviding {
    // MARK: Keychain keys
    enum KeychainKey: String, CaseIterable {
        case authenticationToken = "com.strv.networking.authenticationToken"
        case authenticationTokenExpirationDate = "com.strv.networking.authenticationTokenExpirationDate"
        case refreshToken = "com.strv.networking.refreshToken"
        case refreshTokenExpirationDate = "com.strv.networking.refreshTokenExpirationDate"
    }

    // MARK: Public properties
    public var authenticationToken: String? {
        string(key: .authenticationToken)
    }

    public var authenticationTokenExpirationDate: Date? {
        date(key: .authenticationTokenExpirationDate)
    }

    public var refreshToken: String? {
        string(key: .refreshToken)
    }

    public var refreshTokenExpirationDate: Date? {
        date(key: .refreshTokenExpirationDate)
    }

    public let refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging

    // MARK: Private properties
    private lazy var keychain = KeychainSwift()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        return dateFormatter
    }()

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

        setDate(
            value: authenticationTokenData.authenticationTokenExpirationDate,
            key: .authenticationTokenExpirationDate
        )

        setString(
            value: authenticationTokenData.refreshToken,
            key: .refreshToken
        )

        setDate(
            value: authenticationTokenData.refreshTokenExpirationDate,
            key: .refreshTokenExpirationDate
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

    func setDate(value: Date?, key: KeychainKey) {
        guard let date = value else {
            setString(value: nil, key: key)
            return
        }

        setString(
            value: dateFormatter.string(from: date),
            key: key
        )
    }

    func string(key: KeychainKey) -> String? {
        keychain.get(key.rawValue)
    }

    func remove(key: KeychainKey) {
        keychain.delete(key.rawValue)
    }

    func date(key: KeychainKey) -> Date? {
        if let date = string(key: key) {
            return dateFormatter.date(from: date)
        }

        return nil
    }
}
