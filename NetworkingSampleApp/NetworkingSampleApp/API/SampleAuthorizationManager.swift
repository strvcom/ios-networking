//
//  SampleAuthorizationManager.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Networking
import Foundation

final class SampleAuthorizationManager: AuthorizationManaging {
    let storage: AuthorizationStorageManaging = SampleAuthorizationStorageManager()
    
    private lazy var apiManager: APIManager = {
        let loggingInterceptor = LoggingInterceptor()
        
        return APIManager(
            urlSession: URLSession.shared,
            requestAdapters: [loggingInterceptor],
            responseProcessors: [
                loggingInterceptor,
                StatusCodeProcessor(),
            ],
            errorProcessors: [loggingInterceptor]
        )
    }()
    
    func refreshAuthorizationData(with refreshToken: String) async throws -> Networking.AuthorizationData {
        let request = SampleRefreshTokenRequest(refreshToken: refreshToken)
        let response: SampleUserAuthResponse = try await apiManager.request(
            SampleAuthRouter.refreshToken(request)
        )
        return response.authData
    }
}
