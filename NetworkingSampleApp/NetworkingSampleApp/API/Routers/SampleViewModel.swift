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
        
        return APIManager(
            urlSession: URLSession.shared,
            requestAdapters: [
                loggingInterceptor,
                AuthorizationTokenInterceptor(authorizationManager: authManager)
            ],
            responseProcessors: [
                loggingInterceptor,
                AuthorizationTokenInterceptor(authorizationManager: authManager),
                StatusCodeProcessor(),
            ],
            errorProcessors: [loggingInterceptor]
        )
    }()
    
    func runNetworkingExamples() {
        Task {
            do {
                //HTTP 200
                // try await loadUserList()
                
                // HTTP 400
//                try await login(
//                    email: SampleAPIConstants.validEmail,
//                    password: SampleAPIConstants.noPassword
//                )
                
                // HTTP 200/401
                try await checkAuthorizationStatus()
            } catch {
                os_log("❌ Error while getting data: \(error)")                
            }
        }
    }
    
    func loadUserList() async throws {
        try await apiManager.request(
            SampleUserRouter.users(page: 2)
        )
    }
    
    func login(email: String?, password: String?) async throws {
        let request = SampleUserAuthRequest(email: email, password: password)
        let response: SampleUserAuthResponse = try await apiManager.request(
            SampleAuthRouter.loginUser(user: request)
        )
        
        let data = AuthorizationData(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
        // Save login token data to auth storage.
        try await authManager.storage.save(data: data)
    }

    func checkAuthorizationStatus() async throws {
        try await apiManager.request(
            SampleAuthRouter.status
        )
    }
}
