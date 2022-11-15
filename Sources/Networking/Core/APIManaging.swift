//
//  APIManaging.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines API managing

/// Protocol APIManaging defines API layer
/// API layer calls request and returns response
public protocol APIManaging {
    /// Creates request for API endpoint defined by ``Requestable`` and returns  ``Response``
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - retry: configuration for retrying behavior
    /// - Returns: data and URLResponse
    func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response

    /// Creates publisher streaming `Decodable` object  for API endpoint defined by ``Requestable``
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - decoder: provided JSONDecoder
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
    
    /// Simplifies request using default `JSONDecoder` and default ``RetryConfiguration``
    /// - Parameter endpoint: API endpoint definition
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable) async throws -> DecodableResponse {
        try await request(endpoint, decoder: JSONDecoder(), retryConfiguration: RetryConfiguration.default)
    }

    /// Simplifies request using default `JSONDecoder`
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - retry: configuration for retrying behavior
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> DecodableResponse {
        try await request(endpoint, decoder: JSONDecoder(), retryConfiguration: retryConfiguration)
    }
}
