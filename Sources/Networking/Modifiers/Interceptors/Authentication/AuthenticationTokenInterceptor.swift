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
    // MARK: Private properties

    private var authenticationManager: AuthenticationManaging

    // MARK: Init

    public init(authenticationManager: AuthenticationManaging) {
        self.authenticationManager = authenticationManager
    }

    // MARK: RequestInterceptor

    public func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error> {
        // if endpoint requires auth header add it

        guard endpointRequest.endpoint.isAuthenticationRequired else {
            return requestPublisher
        }

        // throw error if not valid authentication token
        return requestPublisher
            .tryMap { [weak self] request in
                guard let self = self else {
                    return request
                }

                let authorizedRequestResult = self.authenticationManager.authorizeRequest(request)
                switch authorizedRequestResult {
                case let .success(request):
                    return request
                case let .failure(error):
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with _: URLRequest, for _: EndpointRequest) -> AnyPublisher<Response, Error> {
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

                // TODO:
                return responsePublisher

//                // Authenticate and throw retrying error to recall whole api manager request flow
//                return self.authenticationManager.authorize(
//                    Just(urlRequest)
//                        .setFailureType(to: Error.self)
//                        .eraseToAnyPublisher()
//                )
//                .tryMap { _ -> Response in
//                    throw AuthenticationError.unauthorized
//                }
//                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
