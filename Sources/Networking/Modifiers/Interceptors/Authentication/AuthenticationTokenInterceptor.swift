//
//  AuthorizationTokenProcessing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines authentication handling in requests

open class AuthorizationTokenInterceptor: RequestInterceptor {
    private lazy var cancellables = Set<AnyCancellable>()

    private var authenticationManager: AuthenticationManaging

    public init(authenticationManager: AuthenticationManaging) {
        self.authenticationManager = authenticationManager
    }

    public func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error> {
        // if is auth token needed
        // proceed authorization

        guard endpointRequest.endpoint.isAuthenticationRequired else {
            return requestPublisher
        }

        return authenticationManager.authorize(requestPublisher)
    }

    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for _: EndpointRequest) -> AnyPublisher<Response, Error> {
        // check if response code 401
        // authenticate
        // recall requests

        responsePublisher
            .catch { [weak self] error -> AnyPublisher<Response, Error> in
                guard
                    let self = self,
                    let networkError = error as? NetworkError,
                    case let .unacceptableStatusCode(statusCode, _, _) = networkError,
                    statusCode == 401
                else {
                    return responsePublisher
                }

                // Authenticate and throw retrying error to recall whole api manager request flow
                return self.authenticationManager.authorize(
                    Just(urlRequest)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                )
                .tryMap { _ -> Response in
                    throw AuthenticationError.unauthorized
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
