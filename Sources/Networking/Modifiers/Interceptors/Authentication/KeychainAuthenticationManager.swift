//
//  KeychainAuthenticationManager.swift
//
//
//  Created by Tomas Cejka on 10.12.2021.
//

import Foundation
import KeychainSwift

// TODO: solve multiple instances

// MARK: - KeychainAuthenticationManager

/// Implementation of ``AuthenticationManaging`` using `Keychain`
open class KeychainAuthenticationManager {
    // MARK: Private properties

    private lazy var keychain = KeychainSwift()
    private lazy var jsonEncoder = JSONEncoder()
    private lazy var jsonDecoder = JSONDecoder()

    private let authenticationProvider: AuthenticationProviding
    private let authorizationHeaderKey: String

    /// Model loaded from Keychain
    private var authenticationTokenData: AuthenticationTokenData? {
        getObject(AuthenticationTokenDataModel.self, key: .authenticationModel)
    }

    /// User's authenticationToken expiration date
    private var isExpired: Bool {
        guard let authenticationTokenExpirationDate = authenticationTokenData?.authenticationTokenExpirationDate else {
            return true
        }
        return authenticationTokenExpirationDate < Date()
    }

    /// Creates an instance of ``KeychainAuthenticationManager`` with injected authentication provider
    /// - Parameter authenticationProvider: Implementation of `AuthenticationProviding`
    public init(
        authenticationProvider: AuthenticationProviding,
        authorizationHeaderKey: String = HTTPHeader.HeaderField.authorization.rawValue
    ) {
        self.authenticationProvider = authenticationProvider
        self.authorizationHeaderKey = authorizationHeaderKey
    }
}

// MARK: - AuthenticationManaging protocol

extension KeychainAuthenticationManager: AuthenticationManaging {
    public var isAuthenticated: Bool {
        authenticationTokenData?.authenticationToken != nil && !isExpired
    }

    public func revoke() {
        // delete all keys
        KeychainKey.allCases.forEach {
            remove(key: $0)
        }
    }

    public func authenticate() {
        authenticationProvider.authenticate()
    }

    public func store(_ authenticationTokenData: AuthenticationTokenData) {
        // map protocol to codable model
        let authenticationModel = AuthenticationTokenDataModel(
            authenticationToken: authenticationTokenData.authenticationToken,
            refreshToken: authenticationTokenData.refreshToken,
            authenticationTokenExpirationDate: authenticationTokenData.authenticationTokenExpirationDate,
            refreshTokenExpirationDate: authenticationTokenData.refreshTokenExpirationDate
        )
        // save to keychain
        setObject(authenticationModel, key: .authenticationModel)
    }
}

// MARK: Keychain keys

enum KeychainKey: String, CaseIterable {
    case authenticationModel = "com.strv.networking.keychain.authenticationModel"
}

// MARK: - Private helper methods

extension KeychainAuthenticationManager {
    /// Save encodable model to keychain
    func setObject<Object: Encodable>(_ object: Object, key: KeychainKey) {
        guard let data = try? jsonEncoder.encode(object) else {
            return
        }
        keychain.set(data, forKey: key.rawValue)
    }

    /// Load decodable model from keychain
    /// - Returns: Decodable model
    func getObject<Object: Decodable>(_: Object.Type, key: KeychainKey) -> Object? {
        let data = keychain.getData(key.rawValue)
        guard let data = data,
              let authenticationTokenData = try? jsonDecoder.decode(Object.self, from: data)
        else {
            return nil
        }
        return authenticationTokenData
    }

    /// Delete value in Keychain
    /// - Parameter key: Key to deleting value
    func remove(key: KeychainKey) {
        keychain.delete(key.rawValue)
    }
}

// MARK: - RequestAuthorizing

extension KeychainAuthenticationManager: RequestAuthorizing {
    public func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError> {
        // check user's authenticationToken
        guard let authenticationToken = authenticationTokenData?.authenticationToken else {
            return .failure(.missingAuthenticationToken)
        }
        // check user's authenticationToken expiration date
        guard !isExpired else {
            return .failure(.expiredAuthenticationToken)
        }

        /*
         authenticationToken is valid
         add authorization header to request
         return authenticatedRequest
         */
        var authenticatedRequest = request
        authenticatedRequest.setValue(authenticationToken, forHTTPHeaderField: authorizationHeaderKey)
        return .success(authenticatedRequest)
    }
}
