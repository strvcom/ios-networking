//
//  AuthorizationTokenInterceptor.swift
//  
//
//  Created by Dominika Gajdová on 08.12.2022.
//

import Foundation

// MARK: - Defines authentication handling in requests
public final class AuthorizationTokenInterceptor: RequestInterceptor {
    private var authorizationManager: AuthorizationManaging
    
    public init(authorizationManager: AuthorizationManaging) {
        self.authorizationManager = authorizationManager
    }
    
    public func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest {
        guard endpointRequest.endpoint.isAuthenticationRequired else {
            return request
        }
        
        return try await authorizationManager.authorize(request, for: endpointRequest)
    }
    
    public func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response {
        guard let httpResponse = response.response as? HTTPURLResponse else {
            throw NetworkError.noStatusCode(response: response)
        }
        
        /// Request was unauthorized but required valid authorization.
        guard httpResponse.statusCode == 401, endpointRequest.endpoint.isAuthenticationRequired else {
            return response
        }
        
        /// Refresh token is invalid, user should be logged out.
        if endpointRequest.endpoint.isRefreshTokenRequest {
            throw AuthorizationError.expiredRefreshToken
        }
        
        return response
    }
    
    public func process(_ error: Error, for endpointRequest: EndpointRequest) async -> Error {
        error
    }
}
