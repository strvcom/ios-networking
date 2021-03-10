//
//  RequestRetrying.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// manage retry for the request due to error
public protocol RequestRetrying {
    func retry<Output>(_ request: AnyPublisher<Output, Error>, error: Error, in apiCall: APICall) -> AnyPublisher<Output, Error>
    func finished(_ apiCall: APICall)
}
