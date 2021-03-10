//
//  ExampleAPIErrorProcessing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 10.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine
import ios_networking

// custom api business logic error solution
class ExampleAPIErrorProcessing: ResponseProcessing {
    private lazy var decoder = JSONDecoder()
    func process(_ responsePublisher: AnyPublisher<Response, Error>, with request: URLRequest, in apiCall: APICall) -> AnyPublisher<Response, Error> {
        responsePublisher
            .tryCatch { error -> AnyPublisher<Response, Error> in
                guard let networkError = error as? NetworkError, case .unacceptableStatusCode(let statusCode, _, let response) = networkError, statusCode == 400 else {
                    return responsePublisher
                }

                let apiError = try self.decoder.decode(ExampleAPIError.self, from: response.data)
                throw apiError
            }.eraseToAnyPublisher()
    }
}
