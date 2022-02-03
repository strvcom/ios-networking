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
    func process(_ responsePublisher: AnyPublisher<Response, Error>, with _: URLRequest, for _: EndpointRequest) -> AnyPublisher<Response, Error> {
        responsePublisher
            .tryCatch { error -> AnyPublisher<Response, Error> in
                guard let networkError = error as? NetworkError,
                      case let .unacceptableStatusCode(statusCode, _, response) = networkError,
                      statusCode == 400
                else {
                    return responsePublisher
                }

                if let apiError = try? self.decoder.decode(SampleAPIError.self, from: response.data) {
                    throw apiError
                }

                throw error
            }
            .eraseToAnyPublisher()
    }
}
