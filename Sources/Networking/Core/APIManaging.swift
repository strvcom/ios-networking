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
    /// - Returns: Publisher streaming response
    func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error>

    /// Creates publisher streaming `Decodable` object  for API endpoint defined by ``Requestable``
    /// - Returns: Publisher streaming decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder) -> AnyPublisher<DecodableResponse, Error>
}

// MARK: - Provide request with default json decoder

public extension APIManaging {

    /// Default implementation using `JSONDecoder`
    /// - Returns: Publisher streaming decodable object
    func request<Body: Decodable>(_ endpoint: Requestable) -> AnyPublisher<Body, Error> {
        request(endpoint, decoder: JSONDecoder())
    }
}

// MARK: - Provide request with default decoding

public extension APIManaging {
    /// Tries to decode `Data` from ``Response`` to decodable object
    /// - Returns: Publisher streaming decodable object
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint)
            .tryMap { try decoder.decode(DecodableResponse.self, from: $0.data) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Retry
// TODO: JK idea about retry approach
/*
 apiManager.request(request, retryCount: 5, retryDelay: 3) { error in
   return true
 }
 */

public struct RetryConfiguration {
    let retryCount: Int
    let retryDelay: TimeInterval
    let retryHandler: (Error) -> Bool

    public init() {
        retryCount = 3
        retryDelay = 0.2
        retryHandler = { _ in
            true
        }
    }
}

public extension APIManaging {
    func request(
        _ endpoint: Requestable,
        retry _: RetryConfiguration = RetryConfiguration()
    ) -> AnyPublisher<Response, Error> {
        request(endpoint)
    }
}
