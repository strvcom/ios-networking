//
//  AuthenticationTokenManaging.swift
//
//  Created by Tomas Cejka on 22.03.2021.
//

import Combine
import Foundation

// MARK: - Defines authentication managing by authentication token

public protocol AuthenticationTokenManaging: AnyObject, AuthenticationManaging {
    // auth token management values
    var authenticationToken: String? { get }
    var authenticationTokenExpirationDate: Date? { get }
    var refreshToken: String? { get }
    var refreshTokenExpirationDate: Date? { get }

    // custom header field for authorization
    var headerField: String { get }
    var isExpired: Bool { get }

    var refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging { get }

    // allows set authentication data from outside
    func store(_ authenticationTokenData: AuthenticationTokenData)
}

// MARK: - Default implementation for authentication token managing

public extension AuthenticationTokenManaging {
    var headerField: String {
        "Authorization"
    }

    var isAuthenticated: Bool {
        authenticationToken != nil && !isExpired
    }

    var isExpired: Bool {
        guard let authenticationTokenExpirationDate = authenticationTokenExpirationDate else {
            return true
        }
        return authenticationTokenExpirationDate <= Date()
    }

    func authenticate() -> AnyPublisher<Void, AuthenticationError> {
        guard let refreshToken = refreshToken else {
            return Fail(error: .missingRefreshToken).eraseToAnyPublisher()
        }

        if let authenticationTokenExpirationDate = authenticationTokenExpirationDate,
           authenticationTokenExpirationDate <= Date()
        {
            // swiftlint:disable:previous opening_brace
            return Fail(error: .expiredRefreshToken).eraseToAnyPublisher()
        }

        return refreshAuthenticationTokenManager
            .refreshAuthenticationToken(refreshToken)
            .handleEvents(receiveOutput: { [weak self] authenticationTokenData in
                self?.store(authenticationTokenData)
            })
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

// MARK: - AuthenticationTokenManaging & AuthenticationProviding

public extension AuthenticationTokenManaging where Self: RequestAuthorizing {
    func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError> {
        guard isAuthenticated,
              let authenticationToken = authenticationToken
        else {
            guard authenticationToken == nil else {
                return .failure(.expiredAuthenticationToken)
            }

            return .failure(.missingAuthenticationToken)
        }

        var authenticatedRequest = request
        authenticatedRequest.setValue(authenticationToken, forHTTPHeaderField: headerField)

        return .success(authenticatedRequest)
    }
}
