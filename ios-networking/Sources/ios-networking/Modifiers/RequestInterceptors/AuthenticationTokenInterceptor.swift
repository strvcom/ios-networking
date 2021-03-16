//
//  AuthorizationTokenProcessing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 09.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

public enum AuthorizationTokenError: Error, LocalizedError, Retriable {
    case missingAuthorizationToken
    case expiredAuthorizationToken
    
    public var errorDescription: String? {
        switch self {
        case .missingAuthorizationToken:
            return NSLocalizedString("Missing authorization token", comment: "")
        case .expiredAuthorizationToken:
            return NSLocalizedString("Authorization token expired", comment: "")
        }
    }
    
    public var shouldRetry: Bool {
        true
    }
}

public class AuthorizationTokenInterceptor: RequestInterceptor {

    var cancellables = Set<AnyCancellable>()

    private var accessTokenManager: AccessTokenManaging?
    private let headerField: String
    private let refreshTokenPublisher: RefreshTokenPublishing
    private lazy var refreshToken: Future<String, Error> = Future { promise in
        self.refreshTokenPublisher.refreshAuthenticationToken()
            .sink { completion in
                switch completion {
                case .failure(let error):
                    promise(.failure(error))
                default:
                    break
                }
            } receiveValue: { value in
                promise(.success(value))
            }
            .store(in: &self.cancellables)
    }
    
    public init(accessTokenManager: AccessTokenManaging?, refreshTokenPublisher: RefreshTokenPublishing, headerField: String = "Authorization") {
        self.accessTokenManager = accessTokenManager
        self.headerField = headerField
        self.refreshTokenPublisher = refreshTokenPublisher
    }
    
    public func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error> {
        // if is auth token needed
        // check token available & valid
        // add to header
        // else refresh token
        // add to header & recall original request
        
        guard endpointRequest.endpoint.authenticated else {
            return requestPublisher
        }
        
        if let accessToken = accessTokenManager?.accessToken, !(accessTokenManager?.isExpired ?? true) {
            
            return requestPublisher
                .map { request -> URLRequest in
                    var mutableRequest = request
                    mutableRequest.setValue(accessToken, forHTTPHeaderField: self.headerField)
                    return mutableRequest
                }.eraseToAnyPublisher()
            
        }
        
        let error: AuthorizationTokenError =  accessTokenManager?.accessToken == nil ? .missingAuthorizationToken : .expiredAuthorizationToken
        
        // retry whole flow, do not just add auth header bc it can has unwanted/unexpected impact to other modifiers
        return refreshToken
            .tryMap { _ -> URLRequest in
                throw error
            }
            .eraseToAnyPublisher()
    }
    
    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        
        // check if response code 401
        // refresh token
        // recall requests
        
        responsePublisher
            .catch { error -> AnyPublisher<Response, Error> in
                guard let networkError = error as? NetworkError, case .unacceptableStatusCode(let statusCode, _, _) = networkError, statusCode == 401 else {
                    return responsePublisher
                }
                
                return self.refreshToken
                    .tryMap { _ -> Response in
                        throw error
                    }
                    .eraseToAnyPublisher()
                
            }
            .eraseToAnyPublisher()
    }
}
