//
//  APIManager.swift
//  
//
//  Created by Matej Molnár on 24.11.2022.
//

import Foundation

open class APIManager {
    
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let urlSession: URLSession
    
    // set identifier to URLSession if nil
    public init(
        urlSession: URLSession = URLSession(configuration: .default),
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = []
    ) {
        self.urlSession = urlSession
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
    }
}

extension APIManager: APIManaging {
    public func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response {
        
        print(endpoint)
        print(retryConfiguration)
        
        
        do {
            
            /// create request

            /// adapt request
            
            /// call request
            
            /// retry
            
            
           
            
            return try await urlSession.data(for: endpoint.asRequest())
        }
    }
}

private extension APIManager {
    
}
