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
    func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) throws -> Response

    /// Creates publisher streaming `Decodable` object  for API endpoint defined by ``Requestable``
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - retry: configuration for retrying behavior
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder, retryConfiguration: RetryConfiguration?) throws -> DecodableResponse
}

// MARK: - Provide request with default json decoder, retry configuration

public extension APIManaging {
    /// Simplifies request using  default ``RetryConfiguration``
    /// - Parameter endpoint: API endpoint definition
    /// - Returns: response
    func request(_ endpoint: Requestable) throws -> Response {
        try request(endpoint, retryConfiguration: RetryConfiguration.default)
    }

    /// Simplifies request using as default `JSONDecoder`
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) throws -> DecodableResponse {
        try request(endpoint, decoder: JSONDecoder(), retryConfiguration: retryConfiguration)
    }

    /// Simplifies request using as default `JSONDecoder` and default ``RetryConfiguration``
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable) throws -> DecodableResponse {
        try request(endpoint, decoder: JSONDecoder(), retryConfiguration: RetryConfiguration.default)
    }
    
    /// Tries to decode `Data` from ``Response`` to decodable object
    /// - Returns: decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder, retryConfiguration: RetryConfiguration?) throws -> DecodableResponse {
        try request(endpoint, retryConfiguration: retryConfiguration)
    }
}
