//
//  CredentialsManaging.swift
//
//
//  Created by Tomas Cejka on 04.10.2021.
//

import Combine
import Foundation

// MARK: - Defines authentication managing by credentials

/// Authentication via credentials to get authentication token which is used to authorize requests
public protocol CredentialsManaging: AnyObject, AuthenticationManaging {
    /// Authentication token for HTTP request header
    ///
    /// For case authentication uses for all API calls encoded credentials it should be passed as authentication token as well
    var authenticationToken: String? { get }
    var login: String? { get }
    var password: String? { get }

    /// Key for HTTP header which is used for authentication token
    var headerField: String { get }

    /// Object provides publisher which is triggered when authentication token is invalid, using credentials tries to renew authentication token
    var renewAuthenticationByCredentialsManager: RenewAuthenticationByCredentialsManaging { get }

    /// Enables storing authentication token from outside
    func store(_ authenticationToken: String)
}

// MARK: - Default implementation for authentication credentials managing

public extension CredentialsManaging {
    /// Default value is `Authorization`
    var headerField: String {
        "Authorization"
    }

    /// If authentication token is set returns `true`
    var isAuthenticated: Bool {
        authenticationToken != nil
    }

    /// Authenticates via renewAuthenticationByCredentialsManager and stores authentication token
    /// - Returns: Publisher triggering void when successfully authenticated
    func authenticate() -> AnyPublisher<Void, AuthenticationError> {
        guard let login = login, let password = password else {
            return Fail(error: .missingCredentials).eraseToAnyPublisher()
        }

        return renewAuthenticationByCredentialsManager
            .renewAuthenticationToken(login: login, password: password)
            .handleEvents(receiveOutput: { [weak self] authenticationTokenData in
                self?.store(authenticationTokenData)
            })
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

// MARK: - AuthenticationCredentialsManaging & AuthenticationProviding

public extension CredentialsManaging where Self: RequestAuthorizing {
    /// Authoring request HTTP header adding authentication token to provided header field or returning failure with ``AuthenticationError``
    /// - Parameter request: original URL request
    /// - Returns: Result of successfully authorized request or authentication error
    func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError> {
        guard isAuthenticated,
              let authenticationToken = authenticationToken
        else {
            return .failure(.missingAuthenticationToken)
        }

        var authenticatedRequest = request
        authenticatedRequest.setValue(authenticationToken, forHTTPHeaderField: headerField)

        return .success(authenticatedRequest)
    }
}
