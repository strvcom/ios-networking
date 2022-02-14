//
//  Processor.swift
//
//
//  Created by Martin Vidovic on 14.02.2022.
//

import Foundation
import Combine
import Networking

final class CustomProcessor: ResponseProcessing {
    func process(
        _ responsePublisher: AnyPublisher<Response, Error>,
        with urlRequest: URLRequest,
        for endpointRequest: EndpointRequest
    ) -> AnyPublisher<Response, Error> {
        responsePublisher
            .handleEvents(receiveOutput: { response in
                self.prettyResponseLog(response, from: endpointRequest.endpoint)
            })
            .catch { error -> AnyPublisher<Response, Error> in
                self.prettyErrorLog(error, from: endpointRequest.endpoint)
                return responsePublisher
            }
            .eraseToAnyPublisher()
    }
}
