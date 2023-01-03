//
//  AuthorizationManaging.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public protocol AuthorizationManaging {
    var storage: any AuthorizationStorageManaging { get }
    func authorize(_ urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest
    func refreshToken(_ token: String) async throws -> AuthorizationData
}

extension AuthorizationManaging {
    /// Default authorize implementation.
    public func authorize(_ urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest {
        let authData = await storage.get()
                        
        /// If there is no authData (but authorization is required), refresh should not happen.
        guard let authData else {
            throw AuthorizationError.missingAccessToken
        }
        
        /// Append authentication header to request and return it.
        guard authData.isExpired, !endpointRequest.endpoint.isRefreshTokenRequest else {
            return urlRequest.withAuthorizationHeader(authData.header)
        }
        
        /// Otherwise try refreshing the token and retrying the request.
        let refreshedAuthData = try await refreshToken(authData.refreshToken)
        return urlRequest.withAuthorizationHeader(refreshedAuthData.header)
    }
}

// MARK: - URLRequest helper
extension URLRequest {
    func withAuthorizationHeader(_ value: String) -> URLRequest {
        var mutableRequest = self
        mutableRequest.setValue(
            value,
            forHTTPHeaderField: HTTPHeader.HeaderField.authorization.rawValue
        )
        return mutableRequest
    }
}
