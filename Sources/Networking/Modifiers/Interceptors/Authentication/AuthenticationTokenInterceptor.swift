//
//  AuthenticationTokenInterceptor.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines status code which should throw unauthorized status code
public typealias UnauthorizedStatusCodeHandler = (HTTPStatusCode) -> Bool

// MARK: - Defines authentication handling in requests
open class AuthenticationTokenInterceptor: RequestInterceptor {
    // MARK: Private properties

    private var authenticationProvider: AuthenticationProviding
    private var unauthorizedStatusCodeHandler: UnauthorizedStatusCodeHandler?

    // MARK: Init

    public init(
        authenticationProvider: AuthenticationProviding,
        unauthorizedStatusCodeHandler: UnauthorizedStatusCodeHandler? = nil
    ) {
        self.authenticationProvider = authenticationProvider
        self.unauthorizedStatusCodeHandler = unauthorizedStatusCodeHandler
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

                let authorizedRequestResult = self.authenticationProvider.authorizeRequest(request)
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
        // check if response codes for unauthorized codes & map to auth error
        responsePublisher
            .tryCatch { error -> AnyPublisher<Response, Error> in
                // handle only unacceptable status codes
                guard
                    let networkError = error as? NetworkError,
                    case let .unacceptableStatusCode(statusCode, _, _) = networkError
                else {
                    return responsePublisher
                }

                // default check for 401 if not handler
                guard let handler = self.unauthorizedStatusCodeHandler else {
                    if statusCode == 401 {
                        throw AuthenticationError.unauthorized
                    }

                    return responsePublisher
                }

                if handler(statusCode) {
                    throw AuthenticationError.unauthorized
                }

                return responsePublisher
            }
            .eraseToAnyPublisher()
    }
}
