//
//  AuthorizationTokenInterceptor.swift
//
//
//  Created by Dominika Gajdová on 08.12.2022.
//

import Foundation

// MARK: - Defines authentication handling in requests
/** An interceptor which handles the authorisation process of requests.

 It makes sure that ``AuthorizationManaging/refreshAuthorizationData()`` is triggered in case the ``AuthorizationData`` is expired and that it won't get triggered multiple times at once.
 */
open class AuthorizationTokenInterceptor: RequestInterceptor {
    private var authorizationManager: AuthorizationManaging
    private var refreshTask: Task<Void, Error>?
    
    public init(authorizationManager: AuthorizationManaging) {
        self.authorizationManager = authorizationManager
    }
}

// MARK: - RequestInterceptor conformation
public extension AuthorizationTokenInterceptor {
    func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest {
        guard endpointRequest.endpoint.isAuthenticationRequired else {
            return request
        }
        
        do {
            return try await authorizationManager.authorizeRequest(request)
        } catch {
            // If authorization fails due to expiredAccessToken we should perform refresh
            // and then retry the request authorization again.
            guard case AuthorizationError.expiredAccessToken = error else {
                throw error
            }
            
            try await refreshAuthorizationData()
            
            return try await authorizationManager.authorizeRequest(request)
        }
    }
    
    func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response {
        guard let httpResponse = response.response as? HTTPURLResponse else {
            throw NetworkError.noStatusCode(response: response)
        }
        
        guard
            httpResponse.statusCode == 401,
            endpointRequest.endpoint.isAuthenticationRequired
        else {
            return response
        }
        
        // Since the request failed due to 401 unauthorized while requiring valid authorization, it means that the currently used auth data are probably invalid,
        // hence we can try to refresh the auth data.
        try await refreshAuthorizationData()
        
        // We return the failed response anyway, because we can't retry the request here in the process function.
        // The decision wether to retry or not should be left to the APIManager.
        return response
    }
    
    func process(_ error: Error, for endpointRequest: EndpointRequest) async -> Error {
        error
    }
}

// MARK: Private methods
private extension AuthorizationTokenInterceptor {
    func refreshAuthorizationData() async throws {
        // In case the refresh is already in progress await it.
        if let refreshTask {
            return try await refreshTask.value
        }

        // Otherwise create a new refresh task.
        let newRefreshTask = Task { [weak self] () throws in
            do {
                // Perform the actual refresh logic.
                try await self?.authorizationManager.refreshAuthorizationData()
                /// Make sure to clear refreshTask property after refreshing finishes.
                self?.clearRefreshTask()
            } catch {
                /// Make sure to clear refreshTask property after refreshing finishes.
                self?.clearRefreshTask()
                throw error
            }
        }

        refreshTask = newRefreshTask

        // Await the newly created refresh task.
        return try await newRefreshTask.value
    }
    
    func clearRefreshTask() {
        refreshTask = nil
    }
}
