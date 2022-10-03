//
//  RequestAdapting.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Modifying the request before it's sent

/// A type that is able to modify a request before sending it to an API.
public protocol RequestAdapting {
    /// Modifies a given `URLRequest`
    /// - Parameters:
    ///   - request: The request to be adapted.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The adapted `URLRequest`.
    func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) -> URLRequest
}

// MARK: - Array extension to avoid boilerplate

public extension Array where Element == RequestAdapting {
    /// Applies the adapt method to all objects in a sequence.
    /// - Parameters:
    ///   - request: The request to be adapted.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: A `URLRequest` adapted by all objects in a sequence.
    func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) throws -> URLRequest {
        reduce(request) { request, requestAdapting in
            requestAdapting.adapt(request, for: endpointRequest)
        }
    }
}
