//
//  KeychainAuthenticationManager.swift
//
//
//  Created by Tomas Cejka on 10.12.2021.
//

import Combine
import Foundation
import KeychainSwift

///// <#Description#>
// var isAuthenticated: Bool {
//    authenticationToken != nil && !isExpired
// }
//
///// <#Description#>
// var isExpired: Bool {
//    guard let authenticationTokenExpirationDate = authenticationTokenExpirationDate else {
//        return true
//    }
//    return authenticationTokenExpirationDate <= Date()
// }

// TODO: solve multiple instances

// MARK: - KeychainAuthenticationManager

/// Implementation of ``AuthenticationManaging`` using `Keychain`
open class KeychainAuthenticationManager {
    // MARK: Private properties
    private lazy var keychain = KeychainSwift()
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        return dateFormatter
    }()

    private lazy var jsonEncoder = JSONEncoder()
    private lazy var jsonDecoder = JSONDecoder()
    private let authenticationProvider: AuthenticationProviding
    private let authorizationHeaderKey: String
    private let authenticationTokenMapper: AuthenticationTokenMapping

    /// Creates an instance of ``KeychainAuthenticationManager`` with injected authentication provider
    /// - Parameter authenticationProvider: Implementation of `AuthenticationProviding`
    public init(
        authenticationProvider: AuthenticationProviding,
        authorizationHeaderKey: String = HTTPHeader.HeaderField.authorization.rawValue
    ) {
        self.authenticationProvider = authenticationProvider
        self.authorizationHeaderKey = authorizationHeaderKey
        self.authenticationTokenMapper = AuthenticationTokenMapper()
    }
}

// MARK: - AuthenticationManaging protocol
extension KeychainAuthenticationManager: AuthenticationManaging {
    public var authenticationToken: String? {
        authenticationTokenData?.authenticationToken
    }
    
    public var authenticationTokenExpirationDate: Date? {
        authenticationTokenData?.authenticationTokenExpirationDate
    }
    
    public var refreshToken: String? {
        authenticationTokenData?.refreshToken
    }
    
    public var refreshTokenExpirationDate: Date? {
        authenticationTokenData?.refreshTokenExpirationDate
    }
    
    public var isAuthenticated: Bool {
        authenticationToken != nil && !isExpired
    }

    private var authenticationTokenData: AuthenticationTokenData? {
        getObject(AuthenticationTokenDataModel.self, key: .authenticationObject)
    }

    private var isExpired: Bool {
        guard let authenticationTokenExpirationDate = authenticationTokenExpirationDate else {
            return true
        }
        return authenticationTokenExpirationDate < Date()
    }
    
    public func revoke() {
        // delete all keys
        KeychainKey.allCases.forEach {
            remove(key: $0)
        }
    }

    public func authenticate() -> AnyPublisher<Void, AuthenticationError> {
        authenticationProvider.authenticate()
    }

    public func store(_ authenticationTokenData: AuthenticationTokenData) {
        // map protocol to codable model
        let authenticationModel = authenticationTokenMapper.createModel(authenticationTokenData)
        // save to keychain
        setObject(authenticationModel, key: .authenticationObject)
    }
}

// MARK: Keychain keys

enum KeychainKey: String, CaseIterable {
    case authenticationToken = "com.strv.networking.keychain.authenticationToken"
    case authenticationHeader = "com.strv.networking.keychain.authenticationHeader"
    case authenticationObject = "com.strv.networking.keychain.authorizationObject"
}

// MARK: - Private helper methods

extension KeychainAuthenticationManager {
    func setObject<Object: Encodable>(_ object: Object, key: KeychainKey) {
        guard let data = try? jsonEncoder.encode(object) else {
            return
        }
        keychain.set(data, forKey: key.rawValue)
    }

    func getObject<Object: Decodable>(_ object: Object.Type, key: KeychainKey) -> Object? {
        let data = keychain.getData(key.rawValue)
        guard let data = data,
              let authenticationTokenData = try? jsonDecoder.decode(Object.self, from: data)
        else {
            return nil
        }
        return authenticationTokenData
    }

    func setString(_ value: String?, key: KeychainKey) {
        guard let value = value else {
            remove(key: key)
            return
        }
        keychain.set(value, forKey: key.rawValue)
    }

    func setDate(_ value: Date?, key: KeychainKey) {
        guard let date = value else {
            remove(key: key)
            return
        }

        setString(dateFormatter.string(from: date), key: key)
    }

    func string(key: KeychainKey) -> String? {
        keychain.get(key.rawValue)
    }

    func date(key: KeychainKey) -> Date? {
        if let date = string(key: key) {
            return dateFormatter.date(from: date)
        }

        return nil
    }

    func remove(key: KeychainKey) {
        keychain.delete(key.rawValue)
    }
}

extension KeychainAuthenticationManager: RequestAuthorizing {
    public func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError> {
        // check user's authenticationToken
        guard let authenticationToken = authenticationToken else {
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
