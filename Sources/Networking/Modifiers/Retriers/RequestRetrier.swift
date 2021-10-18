//
//  RequestRetrier.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

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
            // only retrying errors are managed
            guard let retryingError = error as? Retrying, retryingError.shouldRetry else {
                throw error
            }

            // add to counter
            if !retryCounter.keys.contains(endpointRequest.identifier) {
                retryCounter[endpointRequest.identifier] = (0, error)
            }

            // check retry count
            if let retryCount = retryCounter[endpointRequest.identifier]?.0, retryCount < configuration.retryLimit {
                retryCounter[endpointRequest.identifier]?.0 = retryCount + 1
                return publisher
            } else {
                guard let endpointRequestError = retryCounter[endpointRequest.identifier]?.1 else {
                    throw error
                }
                reset(endpointRequest.identifier)
                throw endpointRequestError
            }
        } catch let caughtError {
            return Fail(error: caughtError).eraseToAnyPublisher()
        }
    }
}

// MARK: - Private retrier extension

private extension RequestRetrier {
    func reset(_ identifier: String) {
        guard let requestIndex = retryCounter.index(forKey: identifier) else {
            return
        }
        retryCounter.remove(at: requestIndex)
    }
}
