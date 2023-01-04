//
//  APIManager.swift
//  
//
//  Created by Matej Molnár on 24.11.2022.
//

import Foundation

/// Default API manager
open class APIManager: APIManaging {
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let urlSession: URLSession
    private let sessionId: String
    private var retryCountCache = RetryCountCache()
    
    public init(
        urlSession: URLSession = URLSession(configuration: .default),
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor()],
        errorProcessors: [ErrorProcessing] = []
    ) {
        /// generate session id in readable format
        sessionId = Date().ISO8601Format()
        self.urlSession = urlSession
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
    }
    
    @discardableResult
    open func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response {
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
            await retryCountCache.reset(for: endpointRequest.id)
            
            return response
        } catch {
            do {
                /// If retry fails (retryCount is 0 or Task.sleep throwed), catch the error and process it with `ErrorProcessing` plugins.
                try await sleepIfRetry(for: error, endpointRequest: endpointRequest, retryConfiguration: retryConfiguration)
                return try await request(endpointRequest, retryConfiguration: retryConfiguration)
            } catch {
                /// error processing
                throw await errorProcessors.process(error, for: endpointRequest)
            }
        }
    }
    
    /// Handle if error triggers retry mechanism and return delay for next attempt
    private func sleepIfRetry(for error: Error, endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) async throws {
        let retryCount = await retryCountCache.value(for: endpointRequest.id)
        
        guard
            let retryConfiguration = retryConfiguration,
            retryConfiguration.retryHandler(error),
            retryConfiguration.retries > retryCount
        else {
            /// reset retry count
            await retryCountCache.reset(for: endpointRequest.id)
            throw error
        }
                
        /// count the delay for retry
        await retryCountCache.increment(for: endpointRequest.id)
        
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

private extension APIManager {
    /// A thread safe wrapper for retry count dictionary.
    actor RetryCountCache {
        private var dict = [String: Int]()
        
        func value(for id: String) -> Int {
            dict[id] ?? 0
        }
        
        func increment(for id: String) {
            dict[id] = (dict[id] ?? 0) + 1
        }
        
        func reset(for id: String) {
            dict.removeValue(forKey: id)
        }
    }
}
