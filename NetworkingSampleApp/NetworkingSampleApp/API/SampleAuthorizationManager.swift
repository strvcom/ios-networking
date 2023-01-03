//
//  SampleAuthorizationManager.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Networking
import Foundation

final class SampleAuthorizationManager: AuthorizationManaging {
    let storage: AuthorizationStorageManaging = AuthorizationInMemoryStorage()
    
    private lazy var apiManager: APIManager = {
        let loggingInterceptor = LoggingInterceptor()
        
        return APIManager(
            urlSession: URLSession.shared,
            requestAdapters: [
                loggingInterceptor,
                AuthorizationTokenInterceptor(authorizationManager: self)
            ],
            responseProcessors: [
                loggingInterceptor,
                AuthorizationTokenInterceptor(authorizationManager: self),
                StatusCodeProcessor(),
            ],
            errorProcessors: [loggingInterceptor]
        )
    }()
    
    func refreshToken(_ token: String) async throws -> AuthorizationData {
        let request = SampleRefreshTokenRequest(refreshToken: token)
        let response: SampleUserAuthResponse = try await apiManager.request(
            SampleAuthRouter.refreshToken(request)
        )
        
        let data = response.authData
        
        // Save login token data to auth storage.
        try await storage.save(data: data)
        return data
    }
}
