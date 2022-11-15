//
//  RequestAdapting.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Modifying the request before it's been sent

/// Protocol defines mechanism to adapt request before being sent to API
public protocol RequestAdapting {
    /// Modifier which adapts request
    /// - Returns: adapted `URLRequest`
    func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest
}

// MARK: - Array extension to avoid boilerplate

public extension Array where Element == RequestAdapting {
    /// Allows array with ``RequestAdapting`` objects to apply one after each other in sequence
    /// - Parameters:
    ///   - request: request to be adapted
    ///   - endpointRequest: endpoint request wrapper
    /// - Returns: `URLRequest` adapted by all object in array in sequence
    func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest {
        try await asyncReduce(request) { request, requestAdapting in
            try await requestAdapting.adapt(request, for: endpointRequest)
        }
    }
}
