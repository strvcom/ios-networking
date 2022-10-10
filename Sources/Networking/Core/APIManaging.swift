//
//  APIManaging.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines api managing

/// A definition of an API layer with methods for handling API requests.
public protocol APIManaging {
    /// Creates a network request for an API endpoint defined by ``Requestable``.
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition.
    ///   - retryConfiguration: configuration for retrying behavior.
    /// - Returns: ``Response``.
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
    /// Simplifies request using a default ``RetryConfiguration``.
    /// - Parameter endpoint: API endpoint requestable definition.
    /// - Returns: ``Response``.
    func request(_ endpoint: Requestable) async throws -> Response {
        try await request(endpoint, retryConfiguration: RetryConfiguration.default)
    }

    /// Simplifies request using a default `JSONDecoder`.
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition.
    ///   - retryConfiguration: configuration for retrying behavior.
    /// - Returns: an object decoded from the response data.
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> DecodableResponse {
        try await request(endpoint, decoder: JSONDecoder(), retryConfiguration: retryConfiguration)
    }

    /// Simplifies request using a default `JSONDecoder` and default ``RetryConfiguration``.
    /// - Parameter endpoint: API endpoint requestable definition.
    /// - Returns: an object decoded from the response data.
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable) async throws -> DecodableResponse {
        try await request(endpoint, decoder: JSONDecoder(), retryConfiguration: RetryConfiguration.default)
    }
}
