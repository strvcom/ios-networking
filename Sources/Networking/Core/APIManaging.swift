//
//  APIManaging.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines api managing

/// Protocol APIManaging defines API layer
/// API layer calls request and returns response
public protocol APIManaging {
    /// Creates publisher streaming ``Response`` for API endpoint defined by ``Requestable``
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - retry: configuration for retrying behavior
    /// - Returns: Publisher streaming response
    func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response

    /// Creates publisher streaming `Decodable` object  for API endpoint defined by ``Requestable``
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - retry: configuration for retrying behavior
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder, retryConfiguration: RetryConfiguration?) async throws -> DecodableResponse
}

// MARK: - Provide request with default json decoder, retry configuration

public extension APIManaging {
    /// Simplifies request using  default ``RetryConfiguration``
    /// - Parameter endpoint: API endpoint definition
    /// - Returns: response
    func request(_ endpoint: Requestable) async throws -> Response {
        try await request(endpoint, retryConfiguration: RetryConfiguration.default)
    }

    /// Simplifies request using as default `JSONDecoder`
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> DecodableResponse {
        try await request(endpoint, decoder: JSONDecoder(), retryConfiguration: retryConfiguration)
    }

    /// Simplifies request using as default `JSONDecoder` and default ``RetryConfiguration``
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable) async throws -> DecodableResponse {
        try await request(endpoint, decoder: JSONDecoder(), retryConfiguration: RetryConfiguration.default)
    }
}
