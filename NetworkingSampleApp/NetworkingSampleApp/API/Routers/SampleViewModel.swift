//
//  SampleViewModel.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 06.12.2022.
//

import Foundation
import Networking
import OSLog

final class SampleViewModel {
    private lazy var authManager = SampleAuthorizationManager()
    private lazy var apiManager: APIManager = {
        let loggingInterceptor = LoggingInterceptor()
        let authorizationInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        return APIManager(
            urlSession: URLSession.shared,
            requestAdapters: [
                loggingInterceptor,
                authorizationInterceptor
            ],
            responseProcessors: [
                loggingInterceptor,
                authorizationInterceptor,
                StatusCodeProcessor(),
            ],
            errorProcessors: [loggingInterceptor]
        )
    }()
    
    func loadUserList() async throws {
        try await apiManager.request(
            SampleUserRouter.users(page: 2)
        )
    }
    
    func login(email: String?, password: String?) async throws {
        let request = SampleUserAuthRequest(email: email, password: password)
        let response: SampleUserAuthResponse = try await apiManager.request(
            SampleAuthRouter.loginUser(request)
        )
        
        let data = response.authData
        // Save login token data to auth storage.
        try await authManager.storage.save(data: data)
    }

    func checkAuthorizationStatus() async throws {
        await withThrowingTaskGroup(of: Void.self, body: { taskGroup in
            for _ in 0..<5 {
                taskGroup.addTask { [weak self] in
                    try await self?.apiManager.request(
                        SampleAuthRouter.status
                    )
                }
            }
        })
    }
}
