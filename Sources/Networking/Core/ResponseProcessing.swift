//
//  ResponseProcessing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines modifying the response after it's been received

public protocol ResponseProcessing {
    func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error>
}

// MARK: - Array extension to avoid boilerplate

public extension Array where Element == ResponseProcessing {
    func process(_ response: Response, with request: URLRequest, for endpoint: EndpointRequest) -> AnyPublisher<Response, Error> {
        let responsePublisher = Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
        return reduce(responsePublisher) { $1.process($0, with: request, for: endpoint) }
    }
}
