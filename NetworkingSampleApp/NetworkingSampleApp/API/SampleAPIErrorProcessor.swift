//
//  SampleAPIErrorProcessor.swift
//  Networking
//
//  Created by Tomas Cejka on 10.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation
import Networking

// custom api business logic error solution
final class SampleAPIErrorProcessor: ResponseProcessing {
    private lazy var decoder = JSONDecoder()

    // Custom error processing sample, sample api provides custom error on status code 400
    func process(_ responsePublisher: Response, with _: URLRequest, for _: EndpointRequest) -> Response {
        responsePublisher
    }
}
