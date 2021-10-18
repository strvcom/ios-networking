//
//  RequestAdapting.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Modifying the request before it's been sent

public protocol RequestAdapting {
    func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error>
}

// MARK: - Array extension to avoid boilerplate

public extension Array where Element == RequestAdapting {
    func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error> {
        let requestPublisher = Just(request)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        return reduce(requestPublisher) { request, requestAdapting in
            requestAdapting.adapt(request, for: endpointRequest)
        }
    }
}
