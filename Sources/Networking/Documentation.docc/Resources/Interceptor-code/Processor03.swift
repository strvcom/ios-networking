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

    }
}
