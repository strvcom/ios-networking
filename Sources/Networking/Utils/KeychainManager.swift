//
//  KeychainManager.swift
//
//
//  Created by Tomas Cejka on 06.10.2021.
//

import Foundation
// import KeychainSwift

// MARK: - Convenience methods & wrapper for KeychainSwift

// MARK: Keychain keys

// enum KeychainKey: String, CaseIterable {
//    case authenticationToken = "com.strv.networking.authenticationToken"
//    case authenticationTokenExpirationDate = "com.strv.networking.authenticationTokenExpirationDate"
//    case refreshToken = "com.strv.networking.refreshToken"
//    case refreshTokenExpirationDate = "com.strv.networking.refreshTokenExpirationDate"
//    // different keys for auth token from authentication by credentials
//    case credentialsAuthenticationToken = "com.strv.networking.credentials.authenticationToken"
//    case password = "com.strv.networking.credentials.password"
//    case login = "com.strv.networking.credentials.credentials.login"
//
//    static let refreshTokenKeys: [KeychainKey] = [.authenticationToken, .authenticationTokenExpirationDate, .refreshToken, .refreshTokenExpirationDate]
//    static let credentialsKeys: [KeychainKey] = [.credentialsAuthenticationToken, .password, .login]
// }
//
//// MARK: - Keychain wrapper with convenience methods
//
// class KeychainManager {
//    // MARK: Private properties
//    private lazy var keychain = KeychainSwift()
//    private lazy var dateFormatter: DateFormatter = {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .full
//        dateFormatter.timeStyle = .full
//        return dateFormatter
//    }()
//
//    // MARK: Public properties
//    var authenticationToken: String? {
//        string(key: .authenticationToken)
//    }
//
//    var authenticationTokenExpirationDate: Date? {
//        date(key: .authenticationTokenExpirationDate)
//    }
//
//    var refreshToken: String? {
//        string(key: .refreshToken)
//    }
//
//    var refreshTokenExpirationDate: Date? {
//        date(key: .refreshTokenExpirationDate)
//    }
//
//    var credentialsAuthenticationToken: String? {
//        string(key: .credentialsAuthenticationToken)
//    }
//
//    var login: String? {
//        string(key: .login)
//    }
//
//    var password: String? {
//        string(key: .password)
//    }
// }
//
//// MARK: - Private helper methods
//
// extension KeychainManager {
//    func setString(value: String?, key: KeychainKey) {
//        guard let value = value else {
//            remove(key: key)
//            return
//        }
//        keychain.set(value, forKey: key.rawValue)
//    }
//
//    func setDate(value: Date?, key: KeychainKey) {
//        guard let date = value else {
//            setString(value: nil, key: key)
//            return
//        }
//
//        setString(
//            value: dateFormatter.string(from: date),
//            key: key
//        )
//    }
//
//    func string(key: KeychainKey) -> String? {
//        keychain.get(key.rawValue)
//    }
//
//    func remove(key: KeychainKey) {
//        keychain.delete(key.rawValue)
//    }
//
//    func date(key: KeychainKey) -> Date? {
//        if let date = string(key: key) {
//            return dateFormatter.date(from: date)
//        }
//
//        return nil
//    }
// }
