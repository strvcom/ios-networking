//
//  AuthenticationInterceptor.swift
//  Networking
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - UnauthorizedStatusCodeHandler

/// Defines status code which should throw authentication error for endpoint
public typealias UnauthorizedResponseHandler = (Requestable, HTTPStatusCode) -> Bool

// MARK: - AuthenticationInterceptor

/// Request interceptor which handles authorizing request and validate responses as authenticated
open class AuthenticationInterceptor {
    // MARK: Private properties

    private var authorizingRequest: RequestAuthorizing
    private var unauthorizedResponseHandler: UnauthorizedResponseHandler?

    // MARK: Init

    /// Creates default authentication interceptor
    /// - Parameters:
    ///   - authorizingRequest: object responsible for authorizing request headers
    ///   - unauthorizedResponseHandler: handler which can define which status codes for request mean unauthenticated error
    public init(
        authorizingRequest: RequestAuthorizing,
        unauthorizedResponseHandler: UnauthorizedResponseHandler? = nil
    ) {
        self.authorizingRequest = authorizingRequest
        self.unauthorizedResponseHandler = unauthorizedResponseHandler
    }
}

// MARK: - RequestInterceptor methods

extension AuthenticationInterceptor: RequestInterceptor {
    /// If the request should be authorized add authorization header
    /// - Parameters:
    ///   - request: original publisher with URLRequest
    ///   - endpointRequest: endpoint request wrapper
    /// - Returns: publisher streaming authorized request (or original if no authentication needed) or failure with authentication error in case authorizing request failed
    public func adapt(_ requestPublisher: URLRequest, for endpointRequest: EndpointRequest) -> URLRequest {
        // if endpoint requires auth header add it
        guard endpointRequest.endpoint.isAuthenticationRequired else {
            return requestPublisher
        }

        // throw error if not valid authentication token
        return requestPublisher
    }

    /// Validate response if status code means unauthorized, uses unauthorizedResponseHandler if present else default checks for default unauthorized 401 status code
    /// - Parameters:
    ///   - responsePublisher: original response publisher
    ///   - _: URLRequest preceded response
    ///   - endpointRequest: endpoint request wrapper
    /// - Returns: original publisher if status code is authorized or mapped error as authentication error
    public func process(_ responsePublisher: Response, with _: URLRequest, for _: EndpointRequest) -> Response {
        // check if response codes for unauthorized codes & map to auth error
        responsePublisher
    }
}
