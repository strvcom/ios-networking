//
//  ResponseProcessing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Defines modifying the response after it's been received

public protocol ResponseProcessing {
    func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error>
}
