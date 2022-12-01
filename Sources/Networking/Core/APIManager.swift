//
//  APIManager.swift
//  
//
//  Created by Matej Molnár on 24.11.2022.
//

import Foundation

/// Default API manager
open class APIManager {
    
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let urlSession: URLSession
    private let sessionId: String
    private var retryCountDict = [String: Int]()
    
    public init(
        urlSession: URLSession = URLSession(configuration: .default),
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = []
    ) {
        /// generate session id in readable format
        sessionId = Date().ISO8601Format()
        self.urlSession = urlSession
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
    }
}

extension APIManager: APIManaging {
    public func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response {
        
        /// create identifiable request from endpoint
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await request(endpointRequest, retryConfiguration: retryConfiguration)
    }
}

private extension APIManager {
    func request(_ endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) async throws -> Response {
        do {
            /// create original url request
            var request = try endpointRequest.endpoint.asRequest()
            
            /// adapt request with all adapters
            request = try await requestAdapters.adapt(request, for: endpointRequest)
            
            /// call request on url session
            var response = try await urlSession.data(for: request)
            
            /// process request
            response = try await responseProcessors.process(response, with: request, for: endpointRequest)
            
            /// reset retry count
            retryCountDict[endpointRequest.id] = 0
            
            return response
        } catch {
            
            try await sleepIfRetry(for: error, endpointRequest: endpointRequest, retryConfiguration: retryConfiguration)
            return try await request(endpointRequest, retryConfiguration: retryConfiguration)
        }
    }
    
    /// Handle if error triggers retry mechanism and return delay for next attempt
    private func sleepIfRetry(for error: Error, endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) async throws {
        var retryCount = retryCountDict[endpointRequest.id] ?? 0
        
        guard
            let retryConfiguration = retryConfiguration,
            retryConfiguration.retryHandler(error),
            retryConfiguration.retries > retryCount
        else {
            /// reset retry count
            retryCountDict[endpointRequest.id] = 0
            throw error
        }
        
        /// count the delay for retry
        retryCount += 1
        retryCountDict[endpointRequest.id] = retryCount
        
        var sleepDuration: UInt64
        switch retryConfiguration.delay {
        case .constant(let timeInterval):
            sleepDuration = UInt64(timeInterval) * 1000000000
        case .progressive(let timeInterval):
            sleepDuration = UInt64(timeInterval) * UInt64(retryCount) * 1000000000
        }
        
        try await Task.sleep(nanoseconds: sleepDuration)
    }
}
