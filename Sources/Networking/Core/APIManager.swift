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

/// Core class of Networking library. APIManager is API layer which is composed from various customizable pieces
///
/// One of core pieces is ``Networking/Networking`` layer which is injected into the class and returns data for `URLRequest`. Other important parts are modifiers and authentication manager. Modifiers are objects which modifies Output or Failure of original request or response publishers. Objects changing `URLRequest` before being sent are called adapters. Adapters confirms ``RequestAdapting`` protocol. After ``Response`` is received from networking layer then come processors into the game. Processors change responses and confirms ``ResponseProcessing`` protocol
/// AuthenticationManager is special entity which help to handle situation when request authorization failed or when response returns ``AuthenticationError``. Typically when HTTP status code is 401. After authentication error AuthenticationManager tries to refresh authentication
/// APIManager holds sessionId information and all request called under one APIManager can be identified by this sessionId
open class APIManager: APIManaging {
    // MARK: Private properties
    private lazy var backgroundQueue = DispatchQueue(label: "com.strv.apimanager")

    private let network: Networking
    private let requestAdapters: [RequestAdapting]
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
        responseProcessors: [ResponseProcessing] = []
    ) {
        sessionId = SessionIdProvider().sessionId
        self.network = network
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.authenticationManager = authenticationManager
    }

    public func request(_ endpoint: Requestable, retry: RetryConfiguration?) -> AnyPublisher<Response, Error> {
        // create identifier of api call
        request(EndpointRequest(endpoint, sessionId: sessionId), retry: retry)
    }
}

// MARK: - Private extension to use same api call for retry

private extension APIManager {
    func request(_ endpointRequest: EndpointRequest, retry: RetryConfiguration?) -> AnyPublisher<Response, Error> {
        // define init upstream
        let initPublisher: AnyPublisher<Requestable, Error>
        if let authenticationPublisher = authenticationPublisher {
            initPublisher = authenticationPublisher
                .map { _ in endpointRequest.endpoint }
                .mapError { $0 }
                .eraseToAnyPublisher()
        } else {
            initPublisher = Just(endpointRequest.endpoint)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        let endpointPublisher = initPublisher
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

        return endpointPublisher
            .tryCatch { [weak self] error -> AnyPublisher<Response, Error> in

                guard let self = self else {
                    throw error
                }

                // retry configuration
                // avoid infinity retries
                if let retry = retry, retry.retries > 0, retry.retryHandler(error) {
                    return Publishers.Delay(
                        upstream: endpointPublisher,
                        interval: RunLoop.SchedulerTimeType.Stride(retry.delay),
                        tolerance: 1,
                        scheduler: RunLoop.main
                    )
                    // one upstream already added
                    .retry(retry.retries - 1)
                    .eraseToAnyPublisher()
                }

                // authentication
                if self.authenticationManager != nil, error is AuthenticationError {
                    // if error while authenticating throw it, do not cycle
                    if !self.isAuthenticationError {
                        self.createAuthenticationPublisher()
                        return self.request(endpointRequest, retry: retry)
                    }
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
