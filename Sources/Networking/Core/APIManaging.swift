//
//  APIManaging.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines api managing

public protocol APIManaging {
    func request(_ endpoint: Requestable, retry: RetryConfiguration?) -> AnyPublisher<Response, Error>
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder, retry: RetryConfiguration?) -> AnyPublisher<DecodableResponse, Error>
}

// MARK: - Provide request with default json decoder, retry configuration

public extension APIManaging {
    func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error> {
        request(endpoint, retry: RetryConfiguration.default)
    }

    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, retry: RetryConfiguration?) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint, decoder: JSONDecoder(), retry: retry)
    }

    func request<DecodableResponse: Decodable>(_ endpoint: Requestable) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint, decoder: JSONDecoder(), retry: RetryConfiguration.default)
    }
}

// MARK: - Provide request with default decoding

public extension APIManaging {
    func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder, retry: RetryConfiguration?) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint, retry: retry)
            .tryMap { try decoder.decode(DecodableResponse.self, from: $0.data) }
            .eraseToAnyPublisher()
    }
}
