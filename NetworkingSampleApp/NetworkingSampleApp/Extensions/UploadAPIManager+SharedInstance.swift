//
//  UploadAPIManager+SharedInstance.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 21.12.2023.
//

import Networking

extension UploadAPIManager {
    static var shared: UploadAPIManaging = {
        var responseProcessors: [ResponseProcessing] = [
            LoggingInterceptor.shared,
            StatusCodeProcessor.shared
        ]
        var errorProcessors: [ErrorProcessing] = [LoggingInterceptor.shared]

    #if DEBUG
        responseProcessors.append(EndpointRequestStorageProcessor.shared)
        errorProcessors.append(EndpointRequestStorageProcessor.shared)
    #endif

        return UploadAPIManager(
            urlSessionConfiguration: .default,
            requestAdapters: [
                LoggingInterceptor.shared
            ],
            responseProcessors: responseProcessors,
            errorProcessors: errorProcessors
        )
    }()
}
