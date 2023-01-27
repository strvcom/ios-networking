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
        
        do {
            return try await authorizationManager.authorizeRequest(request)
        } catch {
            /// If authorization fails due to expiredAccessToken we should perform refresh and then retry the request adaptation again.
            guard case AuthorizationError.expiredAccessToken = error else {
                throw error
            }
            
            try await performRefresh()
            
            return try await adapt(request, for: endpointRequest)
        }
    }
    
    public func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response {
        guard let httpResponse = response.response as? HTTPURLResponse else {
            throw NetworkError.noStatusCode(response: response)
        }
        
        /// Request was unauthorized but required valid authorization.
        guard
            httpResponse.statusCode == 401,
            endpointRequest.endpoint.isAuthenticationRequired
        else {
            return response
        }
        
        return response
    }
    
    public func process(_ error: Error, for endpointRequest: EndpointRequest) async -> Error {
        error
    }
}

// MARK: Private methods
private extension AuthorizationTokenInterceptor {
    func performRefresh() async throws {
        /// If some thread is already refreshing:
        if await refreshingState.getIsRefreshing() {
            defer {
                Task { await refreshingState.signal() }
            }
            
            /// Wait for signal to continue.
            await refreshingState.wait()
        }
        
        /// Lock refreshing state to prevent other threads from trying to refresh as well.
        await refreshingState.setIsRefreshing(true)
        /// Try refreshing authorization data.
        try await authorizationManager.refreshAuthorizationData()
        /// Unlock refreshing state and signal other threads that refreshing is done.
        await refreshingState.setIsRefreshing(false)
        await refreshingState.signal()
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
