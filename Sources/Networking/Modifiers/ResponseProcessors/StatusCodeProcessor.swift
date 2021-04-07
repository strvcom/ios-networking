//
//  StatusCodeProcessor.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Modifier handling validity of response http status codes

open class StatusCodeProcessor: ResponseProcessing {
    
    public init() {}
    
    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        responsePublisher
            .tryMap { response -> Response in
                guard let acceptableStatusCodes = endpointRequest.endpoint.acceptableStatusCodes, !acceptableStatusCodes.isEmpty else {
                    return response
                }
                guard let httpResponse = response.response as? HTTPURLResponse else {
                    throw NetworkError.noStatusCode(response)
                }
                guard acceptableStatusCodes.contains(httpResponse.statusCode) else {
                    throw NetworkError.unacceptableStatusCode(httpResponse.statusCode, acceptableStatusCodes, response)
                }
                return response
            }
            .eraseToAnyPublisher()
    }
}
