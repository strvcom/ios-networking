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

public protocol APIManaging {
    func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error>
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder) -> AnyPublisher<DecodableResponse, Error>
}

// MARK: - Provide request with default json decoder

public extension APIManaging {
    func request<Body: Decodable>(_ endpoint: Requestable) -> AnyPublisher<Body, Error> {
        request(endpoint, decoder: JSONDecoder())
    }
}

// MARK: - Provide request with default decoding

public extension APIManaging {
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
