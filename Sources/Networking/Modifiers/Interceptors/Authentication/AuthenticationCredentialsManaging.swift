//
//  AuthenticationCredentialsManaging.swift
//
//
//  Created by Tomas Cejka on 04.10.2021.
//

import Combine
import Foundation

// MARK: - Defines authentication managing by credentials

public protocol AuthenticationCredentialsManaging: AnyObject, AuthenticationManaging {
    // auth token management values
    // for case authentication token is not present app should return encoded login & password string instead of it
    var authenticationToken: String? { get }
    var login: String { get }
    var password: String { get }

    // custom header field for authorization
    var headerField: String { get }

    var refreshAuthenticationCredentialsManager: RefreshAuthenticationCredentialsManaging { get }

    // allows set authentication data from outside
    func store(_ authenticationToken: String)
}

// MARK: - Default implementation for authentication credentials managing

public extension AuthenticationCredentialsManaging {
    var headerField: String {
        "Authorization"
    }

    var isAuthenticated: Bool {
        authenticationToken != nil
    }

    func authenticate() -> AnyPublisher<Void, AuthenticationError> {
        refreshAuthenticationCredentialsManager
            .refreshAuthenticationToken(login: login, password: password)
            .handleEvents(receiveOutput: { [weak self] authenticationTokenData in
                self?.store(authenticationTokenData)
            })
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

// MARK: - AuthenticationCredentialsManaging & AuthenticationProviding

public extension AuthenticationCredentialsManaging where Self: AuthenticationProviding {
    func authorizeRequest(_ request: URLRequest) -> Result<URLRequest, AuthenticationError> {
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
