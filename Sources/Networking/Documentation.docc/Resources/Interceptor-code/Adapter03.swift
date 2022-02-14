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
        
    }
}
