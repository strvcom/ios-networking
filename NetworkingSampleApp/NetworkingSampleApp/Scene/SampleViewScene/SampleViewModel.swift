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
        
        let config = URLSessionConfiguration.background(withIdentifier: "my.background.task")
        config.isDiscretionary = false
        
        return APIManager(
            urlSession: URLSession(configuration: config),
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
            retryConfiguration: RetryConfiguration(retries: 3, delay: .constant(2), retryHandler: { _ in true })
        )
        
        var resumableData: Data?
        
        do {
            for try await status in downloadStream {
                switch status {
                case .progress(let downloadedBytes, _):
                    os_log("progress %{public}@", type: .info, String(downloadedBytes))
                case .terminated(let data):
                    resumableData = data
                    os_log("terminated %{public}@", type: .info, String(data.count))
                case .completed(let data):
                    os_log("completed %{public}@", type: .info, String(data?.count ?? 0))
                }
            }
        } catch {
            
        }

        if #available(iOS 16.0, *) {
            try? await Task.sleep(for: .seconds(2))
        } else {
            // Fallback on earlier versions
        }
        
        
        let downloadStream2 = try await apiManager.downloadStream(
            SampleUserRouter.media(url: URL(string: videoString)!),
            resumableData: resumableData,
            retryConfiguration: RetryConfiguration(retries: 3, delay: .constant(2), retryHandler: { _ in true })
        )
        
        for try await status in downloadStream2 {
            switch status {
            case .progress(let downloadedBytes, _):
                os_log("progress %{public}@", type: .info, String(downloadedBytes))
            case .terminated(let data):
                os_log("terminated %{public}@", type: .info, String(data.count))
            case .completed(let data):
                os_log("completed %{public}@", type: .info, String(data?.count ?? 0))
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
        try await apiManager.request(
            SampleUserRouter.loginUser(user: request)
        )
    }
}
