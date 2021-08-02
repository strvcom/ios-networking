//
//  AuthenticationTokenManaging.swift
//
//  Created by Tomas Cejka on 22.03.2021.
//

import Combine
import Foundation

// MARK: - Defines authentication managing by authentication token

public protocol AuthenticationTokenManaging: AuthenticationManaging {
    var authenticationToken: String? { get }
    var expirationDate: Date? { get }
    var refreshToken: String? { get }
    var refreshExpirationDate: Date? { get }
    var headerField: String { get }
    var refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging { get }

    var isExpired: Bool { get }
}

// MARK: - Default implementation for authentication token managing

public extension AuthenticationTokenManaging {
    var headerField: String {
        "Authorization"
    }

    func authorize(_ requestPublisher: AnyPublisher<URLRequest, Error>) -> AnyPublisher<URLRequest, Error> {
        if let accessToken = authenticationToken, !isExpired {
            return requestPublisher
                .map { request -> URLRequest in
                    var mutableRequest = request
                    mutableRequest.setValue(accessToken, forHTTPHeaderField: self.headerField)
                    return mutableRequest
                }.eraseToAnyPublisher()
        }

        let error: AuthenticationError = authenticationToken == nil ? .missingAuthenticationToken : .expiredAuthenticationToken

        // retry whole flow, do not just add auth header bc it can has unwanted/unexpected impact to other modifiers
        return refreshAuthenticationTokenManager
            .refreshAuthenticationToken()
            .tryMap { _ -> URLRequest in
                throw error
            }
            .eraseToAnyPublisher()
    }
}
