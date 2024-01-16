//
//  APIManager.swift
//
//
//  Created by Matej Molnár on 24.11.2022.
//

import Foundation

/// Default API manager
open class APIManager: APIManaging, Retryable {
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let responseProvider: ResponseProviding
    private let sessionId: String
    internal var retryCounter = Counter()
    
    public init(
        urlSession: URLSession = .init(configuration: .default),
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        /// generate session id in readable format
        if #unavailable(iOS 15) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            sessionId = dateFormatter.string(from: Date())
        } else {
            sessionId = Date().ISO8601Format()
        }
        
        self.responseProvider = urlSession
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
    }
    
    public init(
        responseProvider: ResponseProviding,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        /// generate session id in readable format
        if #unavailable(iOS 15) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            sessionId = dateFormatter.string(from: Date())
        } else {
            sessionId = Date().ISO8601Format()
        }
        self.responseProvider = responseProvider
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

// MARK: Private
private extension APIManager {
    func request(_ endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) async throws -> Response {
        do {
            /// create original url request
            var request = try endpointRequest.endpoint.asRequest()
            
            /// adapt request with all adapters
            request = try await requestAdapters.adapt(request, for: endpointRequest)
            
            /// get response for given request (usually fires a network request via URLSession)
            var response = try await responseProvider.response(for: request)
            
            /// process request
            response = try await responseProcessors.process(response, with: request, for: endpointRequest)
                        
            /// reset retry count
            await retryCounter.reset(for: endpointRequest.id)
            
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
}
