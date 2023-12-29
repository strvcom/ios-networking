//
//  DownloadAPIManager+SharedInstance.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 12.05.2023.
//

import Networking

extension DownloadAPIManager {
    static let shared: DownloadAPIManaging = {
        var responseProcessors: [ResponseProcessing] = [
            LoggingInterceptor.shared,
            StatusCodeProcessor.shared
        ]
        var errorProcessors: [ErrorProcessing] = [LoggingInterceptor.shared]
        
    #if DEBUG
        responseProcessors.append(EndpointRequestStorageProcessor.shared)
        errorProcessors.append(EndpointRequestStorageProcessor.shared)
    #endif
        
        return DownloadAPIManager(
            urlSessionConfiguration: .default,
            requestAdapters: [
                LoggingInterceptor.shared
            ],
            responseProcessors: responseProcessors,
            errorProcessors: errorProcessors
        )
    }()
}
