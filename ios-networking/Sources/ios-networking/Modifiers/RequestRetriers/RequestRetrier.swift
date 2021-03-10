//
//  RequestRetrier.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

public class RequestRetrier: RequestRetrying {
    public struct Configuration {
        let retryLimit: Int
        
        public init(retryLimit: Int) {
            self.retryLimit = retryLimit
        }
    }
    
    private lazy var retryCounter: [String: Int] = [:]
    private lazy var errors: [String: Error] = [:]
    
    let configuration: Configuration
    
    public init(_ configuration: Configuration = Configuration(retryLimit: 3)) {
        self.configuration = configuration
    }
    
    public func retry<Output>(_ publisher: AnyPublisher<Output, Error>, error: Error, in apiCall: APICall) -> AnyPublisher<Output, Error> {
        
        do {
            // only retriable errors are managed
            guard let retriableError = error as? Retriable, retriableError.shouldRetry else {
                throw error
            }

            errors[apiCall.identifier] = error
            
            // add to counter
            if !retryCounter.keys.contains(apiCall.identifier) {
                retryCounter[apiCall.identifier] = 0
            }
            
            // check retry count
            if let retryCount = retryCounter[apiCall.identifier], retryCount < self.configuration.retryLimit {
                retryCounter[apiCall.identifier] = retryCount + 1
                return publisher
            } else {
                reset(apiCall.identifier)
                guard let apiCallError =  errors[apiCall.identifier] else {
                    throw error
                }
                throw apiCallError
            }
        } catch let caughtError {
            return Fail(error: caughtError).eraseToAnyPublisher()
        }
    }
    
    public func finished(_ apiCall: APICall) {
        reset(apiCall.identifier)
    }
}

private extension RequestRetrier {
    func reset(_ indentifier: String) {
        guard let requestIndex = retryCounter.index(forKey: indentifier) else {
            return
        }
        retryCounter.remove(at: requestIndex)
        guard let errorIndex = errors.index(forKey: indentifier) else {
            return
        }
        errors.remove(at: errorIndex)
    }
}
