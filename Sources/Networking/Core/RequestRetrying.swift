//
//  RequestRetrying.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Defines retry logic for requests

public protocol RequestRetrying {
    func retry<Output>(_ request: AnyPublisher<Output, Error>, with error: Error, for endpointRequest: EndpointRequest) -> AnyPublisher<Output, Error>
    
    func finished(_ endpointRequest: EndpointRequest)
}
