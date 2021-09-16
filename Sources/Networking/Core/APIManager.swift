//
//  APIManager.swift
//  STRV_template
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

    // MARK: Init

    public init(
        network: Networking = URLSession(configuration: .default),
        authenticationManager: AuthenticationManaging? = nil,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [],
        requestRetrier: RequestRetrying = RequestRetrier(RequestRetrier.Configuration())
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMddyyyy_hhmmssa"
        // keep session id in readable format
        sessionId = dateFormatter.string(from: Date())
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

        let authenticationRequest = authenticationPublisher ?? Just(())
            .setFailureType(to: AuthenticationError.self)
            .eraseToAnyPublisher()
        return authenticationRequest
            .map { _ in endpointRequest.endpoint }
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
                guard let self = self else {
                    throw error
                }
                if let authenticationManager = self.authenticationManager,
                   error is AuthenticationError
                {
                    // swiftlint:disable:previous opening_brace
                    if self.authenticationPublisher == nil {
                        self.authenticationPublisher = authenticationManager.authenticate()
                            .map { self.authenticationPublisher = nil }
                            .share()
                            .eraseToAnyPublisher()
                    }

                    return self.request(endpointRequest)
                }

                throw error
            }
            // move to main thread
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
