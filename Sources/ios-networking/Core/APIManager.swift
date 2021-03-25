//
//  APIManager.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Default implementation for api managing

public class APIManager: APIManaging {
    
    private lazy var backgroundQueue = DispatchQueue(label: "com.strv.apimanager")
    
    private let network: Networking
    private let requestAdapters: [RequestAdapting]
    private let requestRetrier: RequestRetrying
    private let responseProcessors: [ResponseProcessing]

    public init(
        network: Networking = URLSession(configuration: .default),
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [],
        requestRetrier: RequestRetrying = RequestRetrier(RequestRetrier.Configuration())
    ) {
        self.network = network
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.requestRetrier = requestRetrier
    }

    public func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error> {
        
        // create idenfier of api call
        return request(EndpointRequest(endpoint))
    }
    
    public func request<DecodableResponse: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<DecodableResponse, Error> {
        request(endpoint)
            .tryMap { try decoder.decode(DecodableResponse.self, from: $0.data) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private extenstion to use same api call for retry

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
                    .mapError { $0 as Error }
                    .map { (urlRequest, $0) }
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
