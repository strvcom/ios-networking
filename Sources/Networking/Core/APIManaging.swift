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
    func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error>
    func request<Body: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder) -> AnyPublisher<Body, Error>
}

// MARK: - Extension to provide default json decoder

public extension APIManaging {
    func request<Body: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<Body, Error> {
        request(endpoint, decoder: decoder)
    }
}
