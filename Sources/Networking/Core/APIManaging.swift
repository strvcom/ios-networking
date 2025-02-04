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
    /// A default `JSONDecoder` used for all requests.
    var defaultDecoder: JSONDecoder { get }

    /// Returns `true` if session has been invalidate and is no longer suitable for usage.
    /// Any other usage of this urlSession will lead to runtime error.
    var urlSessionIsInvalidated: Bool { get }

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

    /// Replaces the responseProvider instance used by APIManager.
    func setResponseProvider(_ provider: ResponseProviding)

    /// Invalidates the current urlSession.
    /// Warning: urlSession must be recreated before further usage
    /// otherwise runtime error is encountered as accessing invalidated session is illegal.
    func invalidateUrlSession() async
}

// MARK: - Provide request with default json decoder, retry configuration

public extension APIManaging {
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

// MARK: - Provide request with default decoding

public extension APIManaging {
    /// Creates a network request for an API endpoint defined by ``Requestable``.
    /// Default implementation trying to decode data from response.
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition.
    ///   - decoder: a `JSONDecoder` used for decoding the response data.
    ///   - retryConfiguration: configuration for retrying behavior.
    /// - Returns: an object decoded from the response data.
    func request<DecodableResponse: Decodable>(
        _ endpoint: Requestable,
        decoder: JSONDecoder,
        retryConfiguration: RetryConfiguration?
    ) async throws -> DecodableResponse {
        let response = try await request(endpoint, retryConfiguration: retryConfiguration)
        return try decoder.decode(DecodableResponse.self, from: response.data)
    }
}
