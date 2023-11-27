//
//  ResponseProcessing.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines modifying the response after it's been received

/// A type that is able to modify a ``Response`` when it's received from the network layer.
public protocol ResponseProcessing: Sendable {
    /// Modifies a given ``Response``.
    /// - Parameters:
    ///   - response: The response to be processed.
    ///   - request: The original URL request.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The processed ``Response``.
    func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response
}

// MARK: - Array extension to avoid boilerplate

public extension Array where Element == ResponseProcessing {
    /// Applies the process method to all objects in a sequence.
    /// - Parameters:
    ///   - response: The response to be processed.
    ///   - request: The original URL request.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: ``Response`` processed by all objects in a sequence.
    func process(_ response: Response, with request: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response {
        try await asyncReduce(response) { response, responseProcessing in
            try await responseProcessing.process(response, with: request, for: endpointRequest)
        }
    }
}
