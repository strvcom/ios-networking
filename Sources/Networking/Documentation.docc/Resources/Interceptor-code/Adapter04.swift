//
//  Adapter.swift
//
//
//  Created by Martin Vidovic on 14.02.2022.
//

import Foundation
import Combine
import Networking

final class CustomAdapter: RequestAdapting {
    func adapt(
        _ requestPublisher: AnyPublisher<URLRequest, Error>,
        for endpointRequest: EndpointRequest
    ) -> AnyPublisher<URLRequest, Error> {
        requestPublisher
            .handleEvents(receiveOutput: { request in
                self.prettyRequestLog(request)
            })
            .catch { error -> AnyPublisher<URLRequest, Error> in
                self.prettyErrorLog(error, from: endpointRequest.endpoint)
                return requestPublisher
            }
            .eraseToAnyPublisher()
    }
}
