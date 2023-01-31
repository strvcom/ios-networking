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
    
    private let apiManager: APIManager = {
        return APIManager(
            responseProvider: MockResponseProvider(with: Bundle.main, sessionId: "2023-01-31T15:08:08Z"),
            requestAdapters: [LoggingInterceptor.shared],
            responseProcessors: [
                LoggingInterceptor.shared,
                StatusCodeProcessor.shared
            ],
            errorProcessors: [LoggingInterceptor.shared]
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
