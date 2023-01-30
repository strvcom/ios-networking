//
//  AuthorizationViewModel.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 06.12.2022.
//

import Foundation
import Networking
import OSLog

final class AuthorizationViewModel: ObservableObject {
    private lazy var authManager = SampleAuthorizationManager()
    private lazy var apiManager: APIManager = {
        let loggingInterceptor = LoggingInterceptor()
        let authorizationInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        
        var responseProcessors: [ResponseProcessing] = [
            loggingInterceptor,
            authorizationInterceptor,
            StatusCodeProcessor()
        ]
        var errorProcessors: [ErrorProcessing] = [loggingInterceptor]
        
#if DEBUG
        let endpointRequestStorageProcessor = EndpointRequestStorageProcessor(
            config: .init(
                multiPeerSharing: .init(shareHistory: true),
                storedSessionsLimit: 5
            )
        )
        responseProcessors.append(endpointRequestStorageProcessor)
        errorProcessors.append(endpointRequestStorageProcessor)
#endif
        
        return APIManager(
            urlSession: URLSession.shared,
            requestAdapters: [
                loggingInterceptor,
                authorizationInterceptor
            ],
            responseProcessors: responseProcessors,
            errorProcessors: errorProcessors
        )
    }()
}

extension AuthorizationViewModel {
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
