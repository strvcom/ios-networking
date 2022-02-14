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

    /// Fully featured API layer providing request API calls, handling authentication issues or solving retries of requests
    /// - Parameters:
    ///   - network: Network layer object
    ///   - authenticationManager: Object managing requirements for authentication
    ///   - requestAdapters: Before request modifiers, * order in important as they run in sequence *
    ///   - responseProcessors: After response processors,  * order in important as they run in sequence *
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

    /// Run the API call flow
    /// - Parameters:
    ///   - endpoint: API endpoint definition
    ///   - retry: Retry configuration for request
    /// - Returns: Publisher streaming response
    public func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) -> AnyPublisher<Response, Error> {
        // create identifier of api call
        request(endpointRequest: EndpointRequest(endpoint, sessionId: sessionId), retryConfiguration: retryConfiguration)
    }
}

// MARK: - Private extension to use same api call for retry

private extension APIManager {
    func request(endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) -> AnyPublisher<Response, Error> {
        /// define upstream for api call flow
        /// in case authentication publisher is created it's initial upstream for all api calls which require authentication

        let endpointRequestPublisher = createInitialRequestPublisher(endpointRequest: endpointRequest)
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

        return endpointRequestPublisher
            .tryCatch { [weak self] error -> AnyPublisher<Response, Error> in

                guard let self = self else {
                    throw error
                }

                
                // authentication publisher
                // if error while authenticating throw it, do not cycle
                if self.authenticationManager != nil,
                   error is AuthenticationError,
                   !self.isAuthenticationError
                {
                    if  self.authenticationPublisher == nil {
                        self.authenticationPublisher = self.createAuthenticationPublisher()
                    }
                    return self.request(endpointRequest: endpointRequest, retryConfiguration: retryConfiguration)
                }

                // retry configuration
                // avoid infinity retries
                if let retryConfiguration = retryConfiguration,
                   retryConfiguration.retries > 0,
                   retryConfiguration.retryHandler(error)
                {
                    return self.createRetryPublisher(originalPublisher: endpointRequestPublisher.eraseToAnyPublisher(), retryConfiguration: retryConfiguration)
                }

                throw error
            }
            // move to main thread
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Create help publishers

private extension APIManager {
    func createAuthenticationPublisher() -> AnyPublisher<Void, AuthenticationError>? {
        // when authentication completes clean up
        authenticationManager?.authenticate()
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    // after authentication, set authenticationPublisher to nil again
                    self?.authenticationPublisher = nil
                    self?.isAuthenticationError = true
                }
            )
            .share()
            .eraseToAnyPublisher()
    }

    func createRetryPublisher(originalPublisher: AnyPublisher<Response, Error>, retryConfiguration: RetryConfiguration) -> AnyPublisher<Response, Error> {
        
        Publishers.Delay(
            upstream: originalPublisher,
            interval: RunLoop.SchedulerTimeType.Stride(retryConfiguration.delay),
            tolerance: 1,
            scheduler: RunLoop.main
        )
        .retry(retryConfiguration.retries)
        .eraseToAnyPublisher()
    }

    func createInitialRequestPublisher(endpointRequest: EndpointRequest) -> AnyPublisher<Requestable, Error> {
        /*
         when there is no authenticationPublisher, or request doesn't need authentication
         just return Requestable
         */
        guard let authenticationPublisher = authenticationPublisher,
              endpointRequest.endpoint.isAuthenticationRequired
        else {
            return Just(endpointRequest.endpoint)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return authenticationPublisher
            .map { _ in endpointRequest.endpoint }
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
