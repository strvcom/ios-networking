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
    private let apiManager: APIManager = {
        let loggingInterceptor = LoggingInterceptor()
        
        var responseProcessors: [ResponseProcessing] = [StatusCodeProcessor(), loggingInterceptor]
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
            requestAdapters: [loggingInterceptor],
            responseProcessors: responseProcessors,
            errorProcessors: errorProcessors
        )
    }()
    
    func runNetworkingExamples() {
        Task {
            do {
                try await downloadMedia()
            } catch {
                print(error)
            }
        }
    }
    
    func downloadMedia() async throws {
        let videoString = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
        
        let downloadStream = try await apiManager.downloadStream(
            SampleUserRouter.media(url: URL(string: videoString)!),
            retryConfiguration: nil
        )
        
        for try await status in downloadStream {
            print(status)
        }
    }
    
    func loadUserList() async throws {
        try await apiManager.request(
            SampleUserRouter.users(page: 2)
        )
    }
    
    func login(email: String?, password: String?) async throws {
        let request = SampleUserAuthRequest(email: email, password: password)
        try await apiManager.request(
            SampleUserRouter.loginUser(user: request)
        )
    }
}
