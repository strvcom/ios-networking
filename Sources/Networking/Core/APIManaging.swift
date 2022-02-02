//
//  APIManaging.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines api managing

/// Protocol APIManaging defines API layer
/// API layer calls request and returns publisher for response
public protocol APIManaging {
    /// Creates publisher streaming ``Response`` for API endpoint defined by ``Requestable``
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - retry: configuration for retrying behavior
    /// - Returns: Publisher streaming response
    func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) -> AnyPublisher<Response, Error>

    /// Creates publisher streaming `Decodable` object  for API endpoint defined by ``Requestable``
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition
    ///   - retry: configuration for retrying behavior
    /// - Returns: Publisher streaming decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder, retryConfiguration: RetryConfiguration?) -> AnyPublisher<DecodableResponse, Error>
}

// MARK: - Provide request with default json decoder, retry configuration

public extension APIManaging {
    /// Simplifies request using  default ``RetryConfiguration``
    /// - Parameter endpoint: API endpoint definition
    /// - Returns: Publisher streaming response
    func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error> {
        request(endpoint, retryConfiguration: RetryConfiguration.default)
    }

    /// Simplifies request using as default `JSONDecoder`
    /// - Returns: Publisher streaming decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint, decoder: JSONDecoder(), retryConfiguration: retryConfiguration)
    }

    /// Simplifies request using as default `JSONDecoder` and default ``RetryConfiguration``
    /// - Returns: Publisher streaming decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint, decoder: JSONDecoder(), retryConfiguration: RetryConfiguration.default)
    }
}

// MARK: - Provide request with default decoding

public extension APIManaging {
    /// Tries to decode `Data` from ``Response`` to decodable object
    /// - Returns: Publisher streaming decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder, retryConfiguration: RetryConfiguration?) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint, retryConfiguration: retryConfiguration)
            .tryMap {
                try decoder.decode(DecodableResponse.self, from: $0.data)
            }
            .eraseToAnyPublisher()
    }
}
