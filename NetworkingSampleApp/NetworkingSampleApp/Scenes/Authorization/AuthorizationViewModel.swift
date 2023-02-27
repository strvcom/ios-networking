//
//  AuthorizationViewModel.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 06.12.2022.
//

import Foundation
import Networking
import OSLog

// TODO: - Either move these extensions to ios-networking package or to a different file in NetworkingSampleApp
extension EndpointRequestStorageProcessor {
    static let shared = EndpointRequestStorageProcessor(
        config: .init(
            multiPeerSharing: .init(shareHistory: true),
            storedSessionsLimit: 5
        )
    )
}

final class AuthorizationViewModel: ObservableObject {
    private lazy var authManager = SampleAuthorizationManager()
    private lazy var apiManager: APIManager = {
        let authorizationInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        
        var responseProcessors: [ResponseProcessing] = [
            LoggingInterceptor.shared,
            authorizationInterceptor,
            StatusCodeProcessor.shared
        ]
        var errorProcessors: [ErrorProcessing] = [LoggingInterceptor.shared]
        
#if DEBUG
        responseProcessors.append(EndpointRequestStorageProcessor.shared)
        errorProcessors.append(EndpointRequestStorageProcessor.shared)
#endif
        
        return APIManager(
            responseProvider: MockResponseProvider(with: Bundle.main, sessionId: "2023-01-31T15:08:08Z"),
            requestAdapters: [
                LoggingInterceptor.shared,
                authorizationInterceptor
            ],
            responseProcessors: responseProcessors,
            errorProcessors: errorProcessors
        )
    }()
}

extension AuthorizationViewModel {
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
        try await apiManager.request(
            SampleAuthRouter.status
        )
    }
}
