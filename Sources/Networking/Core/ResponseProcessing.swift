//
//  ResponseProcessing.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines modifying the response after it's been received

/// When ``Response`` comes from network layer it is processed by response processing object
public protocol ResponseProcessing {
    /// Modifier which processes response
    /// - Returns: New publisher which processes ``Response``
    func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error>
}

// MARK: - Array extension to avoid boilerplate

public extension Array where Element == ResponseProcessing {
    /// Allows array with ``ResponseProcessing`` objects to apply one after each other in sequence
    /// - Parameters:
    ///   - response: response to be processed
    ///   - request: original URL request
    ///   - endpointRequest: endpoint called in request
    /// - Returns: ``Response`` processed by all objects in array in sequence
    func process(_ response: Response, with request: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        let responsePublisher = Just(response)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        return reduce(responsePublisher) { response, responseProcessing in
            responseProcessing.process(response, with: request, for: endpointRequest)
        }
    }
}
