//
//  AuthorizationTokenProcessing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Defines networking errors

public class AuthorizationTokenInterceptor: RequestInterceptor {

    var cancellables = Set<AnyCancellable>()

    private var authenticationManager: AuthenticationManaging
    
    public init(authenticationManager: AuthenticationManaging) {
        self.authenticationManager = authenticationManager
    }
    
    public func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error> {
        // if is auth token needed
        // proceed authorization
        
        guard endpointRequest.endpoint.authenticated else {
            return requestPublisher
        }
        
        return authenticationManager.authenticate(requestPublisher)
    }
    
    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        
        // check if response code 401
        // authenticate
        // recall requests
        
        responsePublisher
            .catch { [weak self] error -> AnyPublisher<Response, Error> in
                guard let self = self, let networkError = error as? NetworkError, case .unacceptableStatusCode(let statusCode, _, _) = networkError, statusCode == 401 else {
                    return responsePublisher
                }
                
                return self.authenticationManager.authenticate(Just(urlRequest).setFailureType(to: Error.self).eraseToAnyPublisher())
                    .tryMap { _ -> Response in
                        throw AuthenticationError.unauthorized
                    }
                    .eraseToAnyPublisher()

            }
            .eraseToAnyPublisher()
    }
}
