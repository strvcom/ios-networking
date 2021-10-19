//
//  StatusCodeProcessor.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Modifier handling validity of response http status codes

/// Response processor validating  ``Response`` http status code against ``Requestable`` API endpoint definition
open class StatusCodeProcessor: ResponseProcessing {
    public init() {}

    /// Processes ``Response`` and throws ``NetworkError/unacceptableStatusCode(statusCode:acceptedStatusCodes:response:)`` in case status code is not contained in allowed status codes or ``NetworkError/noStatusCode(response:)`` if status code is missing in response, when validation successes processor passes original response value
    /// - Parameters:
    ///   - responsePublisher: original response publisher
    ///   - _: URL request
    ///   - endpointRequest: endpoint request
    /// - Returns: Publisher modified with validation of http status code
    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with _: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        responsePublisher
            .tryMap { response -> Response in
                guard let acceptableStatusCodes = endpointRequest.endpoint.acceptableStatusCodes, !acceptableStatusCodes.isEmpty else {
                    return response
                }
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    throw NetworkError.noStatusCode(response: response)
                }
                guard acceptableStatusCodes.contains(httpResponse.statusCode) else {
                    throw NetworkError.unacceptableStatusCode(
                        statusCode: httpResponse.statusCode,
                        acceptedStatusCodes: acceptableStatusCodes,
                        response: response
                    )
                }
                return response
            }
            .eraseToAnyPublisher()
    }
}
