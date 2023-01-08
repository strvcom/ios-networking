//
//  AuthorizationTokenInterceptor.swift
//  
//
//  Created by Dominika Gajdová on 08.12.2022.
//

import Foundation

// MARK: - Defines authentication handling in requests
public final class AuthorizationTokenInterceptor: RequestInterceptor {
    private let refreshingState = RefreshingState()
    private var authorizationManager: AuthorizationManaging
    
    public init(authorizationManager: AuthorizationManaging) {
        self.authorizationManager = authorizationManager
    }
    
    public func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest {
        guard endpointRequest.endpoint.isAuthenticationRequired else {
            return request
        }
        
        let authData = await authorizationManager.storage.get()
                        
        /// If there is no authData (but authorization is required), refresh should not happen.
        guard let authData else {
            throw AuthorizationError.missingAccessToken
        }
        
        /// Append authentication header to request and return it.
        guard authData.isExpired, !endpointRequest.endpoint.isRefreshTokenRequest else {
            return request.withAuthorizationHeader(authData.header)
        }
        
        return try await performRefresh(request, authData: authData)
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

// MARK: Private methods
private extension AuthorizationTokenInterceptor {
    func performRefresh(_ request: URLRequest, authData: AuthorizationData) async throws -> URLRequest {
        /// If some thread is already refreshing:
        if await refreshingState.getIsRefreshing() {
            defer {
                Task { await refreshingState.signal() }
            }
            
            /// 1. Wait for signal to continue.
            await refreshingState.wait()
            /// 2. fetch authData again
            if let authData = await authorizationManager.storage.get() {
                /// 3. skip refreshing and return request with new access token
                return request.withAuthorizationHeader(authData.header)
            } else {
                throw AuthorizationError.missingAccessToken
            }
        }
                
        /// Lock refreshing state to prevent other threads from trying to refresh as well.
        await refreshingState.setIsRefreshing(true)
        /// Otherwise try refreshing the token and retrying the request.
        let refreshedAuthData = try await authorizationManager.refreshToken(authData.refreshToken)
        /// Signal threads that refreshing is done.
        await refreshingState.setIsRefreshing(false)
        await refreshingState.signal()
        /// Some server implementations might require authorized refresh token requests.
        return request.withAuthorizationHeader(refreshedAuthData.header)
    }
}

// MARK: Private actor
private extension AuthorizationTokenInterceptor {
    actor RefreshingState {
        private var isRefreshing = false
        private let semaphore = AsyncSemaphore(value: 0)
        
        func getIsRefreshing() -> Bool {
            isRefreshing
        }
        
        func setIsRefreshing(_ value: Bool) {
            isRefreshing = value
        }
        
        func wait() async {
            await semaphore.wait()
        }
        
        func signal() {
            semaphore.signal()
        }
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
