//
//  APIManaging.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines API managing

/// A definition of an API layer with methods for handling API requests.
public protocol APIManaging {
    /// A default JSONDecoder used for all requests.
    var defaultDecoder: JSONDecoder { get }
    
    /// Creates a network request for an API endpoint defined by ``Requestable``.
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition.
    ///   - retryConfiguration: configuration for retrying behavior.
    /// - Returns: ``Response``.
    @discardableResult
    func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response

    /// Creates a network request for an API endpoint defined by ``Requestable``.
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition.
    ///   - decoder: a JSONDecoder used for decoding the response data.
    ///   - retryConfiguration: configuration for retrying behavior.
    /// - Returns: an object decoded from the response data.
    func request<DecodableResponse: Decodable>(
        _ endpoint: Requestable,
        decoder: JSONDecoder,
        retryConfiguration: RetryConfiguration?
    ) async throws -> DecodableResponse
}

// MARK: - Provide request with default json decoder, retry configuration

public extension APIManaging {
    /// Default JSONDecoder implementation.
    var defaultDecoder: JSONDecoder {
        JSONDecoder.default
    }
    
    /// Simplifies request using a default ``RetryConfiguration``.
    /// - Parameter endpoint: API endpoint requestable definition.
    /// - Returns: ``Response``.
    @discardableResult
    func request(_ endpoint: Requestable) async throws -> Response {
        try await request(endpoint, retryConfiguration: RetryConfiguration.default)
    }

    /// Simplifies request using a default `JSONDecoder`.
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition.
    ///   - retryConfiguration: configuration for retrying behavior.
    /// - Returns: an object decoded from the response data.
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> DecodableResponse {
        try await request(endpoint, decoder: defaultDecoder, retryConfiguration: retryConfiguration)
    }

    /// Simplifies request using a default `JSONDecoder` and default ``RetryConfiguration``.
    /// - Parameter endpoint: API endpoint requestable definition.
    /// - Returns: an object decoded from the response data.
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable) async throws -> DecodableResponse {
        try await request(endpoint, decoder: defaultDecoder, retryConfiguration: RetryConfiguration.default)
    }
}

// MARK: - JSONDecoder static extension

private extension JSONDecoder {
    /// A static JSONDecoder instance used by default implementation of APIManaging
    static let `default` = JSONDecoder()
}
