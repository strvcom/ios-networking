//
//  ResponseProcessing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// modify the response before it's been returned
public protocol ResponseProcessing {
    func process(_ responsePublisher: AnyPublisher<Response, Error>, with request: URLRequest, in apiCall: APICall) -> AnyPublisher<Response, Error>
}
