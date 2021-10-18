//
//  APIManager.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Default implementation for api managing

open class APIManager: APIManaging {
    // MARK: Private properties
    private lazy var backgroundQueue = DispatchQueue(label: "com.strv.apimanager")

    private let network: Networking
    private let requestAdapters: [RequestAdapting]
    private let requestRetrier: RequestRetrying
    private let responseProcessors: [ResponseProcessing]
    private let authenticationManager: AuthenticationManaging?
    private let sessionId: String

    // private publisher which queues other requests waiting for authentication
    private var authenticationPublisher: AnyPublisher<Void, AuthenticationError>?
    private lazy var isAuthenticationError = false

    // MARK: Init

    public init(
        network: Networking = URLSession(configuration: .default),
        authenticationManager: AuthenticationManaging? = nil,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [],
        requestRetrier: RequestRetrying = RequestRetrier(RequestRetrier.Configuration())
    ) {
        sessionId = SessionIdProvider().sessionId
        self.network = network
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.requestRetrier = requestRetrier
        self.authenticationManager = authenticationManager
    }

    public func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error> {
        // create identifier of api call
        request(EndpointRequest(endpoint, sessionId: sessionId))
    }
}

// MARK: - Private extension to use same api call for retry

private extension APIManager {
    func request(_ endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        // define init upstream
        let endpointPublisher: AnyPublisher<Requestable, Error>
        if let authenticationPublisher = authenticationPublisher {
            endpointPublisher = authenticationPublisher
                .map { _ in endpointRequest.endpoint }
                .mapError { $0 }
                .eraseToAnyPublisher()
        } else {
            endpointPublisher = Just(endpointRequest.endpoint)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return endpointPublisher
            // TODO: remove print, temporary debug
            .print()
            // work in background
            .receive(on: backgroundQueue)
            // create request
            .tryMap { try $0.asRequest() }
            // adapt request
            .flatMap { request -> AnyPublisher<URLRequest, Error> in
                self.requestAdapters.adapt(request, for: endpointRequest)
            }
            // call request
            .flatMap { urlRequest -> AnyPublisher<(URLRequest, Response), Error> in
                self.network.requestPublisher(for: urlRequest)
                    .mapError { error in error as Error }
                    .map { response -> (URLRequest, Response) in
                        (urlRequest, response)
                    }
                    .eraseToAnyPublisher()
            }
            // process response
            .flatMap { (request, response) -> AnyPublisher<Response, Error> in
                self.responseProcessors.process(response, with: request, for: endpointRequest)
            }
            .tryCatch { [weak self] error -> AnyPublisher<Response, Error> in
                guard
                    let self = self,
                    self.authenticationManager != nil,
                    error is AuthenticationError
                else {
                    throw error
                }

                // if error while authenticating throw it, do not cycle
                if !self.isAuthenticationError {
                    self.createAuthenticationPublisher()
                    return self.request(endpointRequest)
                }

                throw error
            }
            // move to main thread
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Create authentication publisher

private extension APIManager {
    func createAuthenticationPublisher() {
        if authenticationPublisher == nil {
            // when authentication completes clean up
            authenticationPublisher = authenticationManager?.authenticate()
                .map { [weak self] _ in
                    self?.authenticationPublisher = nil
                    self?.isAuthenticationError = false
                }
                .mapError { [weak self] error in
                    self?.authenticationPublisher = nil
                    self?.isAuthenticationError = true
                    return error
                }
                .share()
                .eraseToAnyPublisher()
        }
    }
}
