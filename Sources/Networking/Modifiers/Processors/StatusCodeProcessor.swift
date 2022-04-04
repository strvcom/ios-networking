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
    ///   - endpointRequest: endpoint request wrapper
    /// - Returns: Publisher modified with validation of http status code
    public func process(_ responsePublisher: Response, with _: URLRequest, for _: EndpointRequest) -> Response {
        responsePublisher
    }
}
