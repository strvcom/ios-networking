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
    private lazy var backgroundQueue = DispatchQueue(label: "com.strv.apimanager")

    private let network: Networking
    private let requestAdapters: [RequestAdapting]
    private let requestRetrier: RequestRetrying
    private let responseProcessors: [ResponseProcessing]
    private let sessionId: String

    public init(
        network: Networking = URLSession(configuration: .default),
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
    }

    public func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error> {
        // create identifier of api call
        request(EndpointRequest(endpoint, sessionId: sessionId))
    }

    public func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint)
            .tryMap { try decoder.decode(DecodableResponse.self, from: $0.data) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private extension to use same api call for retry

private extension APIManager {
    func request(_ endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        // create url request
        Just(endpointRequest.endpoint)
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
            // retry
            .catch { error -> AnyPublisher<Response, Error> in
                self.requestRetrier.retry(self.request(endpointRequest), with: error, for: endpointRequest)
            }
            // move to main thread
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
