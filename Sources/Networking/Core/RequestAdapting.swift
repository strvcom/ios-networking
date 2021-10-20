//
//  RequestAdapting.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Modifying the request before it's sent

/// Protocol defines mechanism to adapt request before being sent to API
public protocol RequestAdapting {
    /// Modifier which adapts request
    /// - Returns: New publisher which adapts `URLRequest`
    func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error>
}

// MARK: - Array extension to avoid boilerplate

public extension Array where Element == RequestAdapting {
    /// Allows array with ``RequestAdapting`` objects to apply one after each other in sequence
    /// - Parameters:
    ///   - request: request to be adapted
    ///   - endpointRequest: endpoint request wrapper
    /// - Returns: `URLRequest` adapted by all object in array in sequence
    func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error> {
        let requestPublisher = Just(request)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        return reduce(requestPublisher) { request, requestAdapting in
            requestAdapting.adapt(request, for: endpointRequest)
        }
    }
}
