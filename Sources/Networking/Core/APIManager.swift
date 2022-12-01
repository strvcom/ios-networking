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
    private var retryCountDict = [String: Int]()
    
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
        
        do {
            /// create request
            let endpointRequest = EndpointRequest(endpoint, sessionId: "")
            var request = try endpoint.asRequest()
            
            /// adapt request
            request = try requestAdapters.adapt(request, for: endpointRequest)
            
            /// call request
            var response = try await urlSession.data(for: endpoint.asRequest())
            
            guard let httpResponse = response.1 as? HTTPURLResponse else {
                throw NetworkError.noStatusCode(response: response)
            }
            
            if
                let acceptableStatusCodes = endpoint.acceptableStatusCodes,
                !acceptableStatusCodes.contains(httpResponse.statusCode)
            {
                throw NetworkError.unacceptableStatusCode(
                    statusCode: httpResponse.statusCode,
                    acceptedStatusCodes: acceptableStatusCodes,
                    response: response)
            }
            
            /// process request
            response = try responseProcessors.process(response, with: request, for: endpointRequest)
            
            /// reset retry count
            retryCountDict[endpoint.identifier] = 0
            
            return response
        } catch {
            var retryCount = retryCountDict[endpoint.identifier] ?? 0
            
            guard
                let retryConfiguration = retryConfiguration,
                retryConfiguration.retryHandler(error),
                retryConfiguration.retries > retryCount
            else {
                /// reset retry count
                retryCountDict[endpoint.identifier] = 0
                throw error
            }
            
            /// retry request after delay
            retryCount += 1
            retryCountDict[endpoint.identifier] = retryCount
            
            let sleepDuration: UInt64 = {
                switch retryConfiguration.delay {
                case .constant(let timeInterval):
                    return UInt64(timeInterval) * 1000000000
                case .progressive(let timeInterval):
                    return UInt64(timeInterval) * UInt64(retryCount) * 1000000000
                }
            }()
            
            try await Task.sleep(nanoseconds: sleepDuration)
            
            return try await request(endpoint, retryConfiguration: retryConfiguration)
        }
    }
}

private extension APIManager {
    
}
