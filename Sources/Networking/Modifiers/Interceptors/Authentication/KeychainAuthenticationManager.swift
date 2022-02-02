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
    private let authenticationProvider: AuthenticationProviding

    /// Creates an instance of ``KeychainAuthenticationManager`` with injected authentication provider
    /// - Parameter authenticationProvider: Implementation of `AuthenticationProviding`
    public init(authenticationProvider: AuthenticationProviding) {
        self.authenticationProvider = authenticationProvider
    }
}

// MARK: - AuthenticationManaging protocol
extension KeychainAuthenticationManager: AuthenticationManaging {
    // TODO:
    public var isAuthenticated: Bool {
        true
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
}

// MARK: - Convenience methods & wrapper for KeychainSwift

// MARK: Keychain keys
enum KeychainKey: String, CaseIterable {
    case authenticationToken = "com.strv.networking.keychain.authenticationToken"
    case authenticationHeader = "com.strv.networking.keychain.authenticationHeader"
}

// MARK: - Private helper methods

extension KeychainAuthenticationManager {
    func setObject<Object: Encodable>(_ object: Object, key: KeychainKey) {
        guard let data = try? jsonEncoder.encode(object) else {
            return
        }
        keychain.set(data, forKey: key.rawValue)
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
    public func authorize(_: URLRequest) -> Result<URLRequest, AuthenticationError> {
        .failure(.missingAuthenticationToken)
//        guard isAuthenticated,
//              let authenticationToken = string(key: authe)
//        else {
//            guard authenticationToken == nil else {
//                return .failure(.expiredAuthenticationToken)
//            }
//
//            return .failure(.missingAuthenticationToken)
//        }
//
//        var authenticatedRequest = request
//        authenticatedRequest.setValue(authenticationToken, forHTTPHeaderField: headerField)
//
//        return .success(authenticatedRequest)
    }
}
