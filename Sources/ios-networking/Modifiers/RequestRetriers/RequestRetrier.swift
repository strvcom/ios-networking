//
//  RequestRetrier.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Default retrying logic

open class RequestRetrier: RequestRetrying {
    public struct Configuration {
        let retryLimit: Int
        let retryDelay: Int // milliseconds
        
        public init(retryLimit: Int = 3, retryDelay: Int = 200) {
            self.retryLimit = retryLimit
            self.retryDelay = retryDelay
        }
    }
    
    private lazy var retryCounter: [String: (Int, Error)] = [:]
    
    let configuration: Configuration
    
    public init(_ configuration: Configuration = Configuration(retryLimit: 3)) {
        self.configuration = configuration
    }
    
    public func retry<Output>(_ publisher: AnyPublisher<Output, Error>, with error: Error, for endpointRequest: EndpointRequest) -> AnyPublisher<Output, Error> {
        
        do {
            // only retriable errors are managed
            guard let retriableError = error as? Retriable, retriableError.shouldRetry else {
                throw error
            }
            
            // add to counter
            if !retryCounter.keys.contains(endpointRequest.identifier) {
                retryCounter[endpointRequest.identifier] = (0, error)
            }
            
            // check retry count
            if let retryCount = retryCounter[endpointRequest.identifier]?.0, retryCount < self.configuration.retryLimit {
                retryCounter[endpointRequest.identifier]?.0 = retryCount + 1
                return publisher
            } else {
                guard let endpointRequestError =  retryCounter[endpointRequest.identifier]?.1 else {
                    throw error
                }
                reset(endpointRequest.identifier)
                throw endpointRequestError
            }
        } catch let caughtError {
            return Fail(error: caughtError).eraseToAnyPublisher()
        }
    }
    
    public func finished(_ endpointRequest: EndpointRequest) {
        reset(endpointRequest.identifier)
    }
}

// MARK: - Private retrier extension

private extension RequestRetrier {
    func reset(_ indentifier: String) {
        guard let requestIndex = retryCounter.index(forKey: indentifier) else {
            return
        }
        retryCounter.remove(at: requestIndex)
    }
}
