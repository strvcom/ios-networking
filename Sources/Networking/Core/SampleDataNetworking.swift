//
//  SampleDataNetworking.swift
//  STRV_template Tests
//
//  Created by Tomas Cejka on 07.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation
import UIKit

// Implementation of networking which reads data from files
open class SampleDataNetworking: Networking {
    private let bundle: Bundle
    private lazy var decoder = JSONDecoder()

    // need to inject bundle
    public init(with bundle: Bundle) {
        self.bundle = bundle
    }

    public func requestPublisher(for request: URLRequest) -> AnyPublisher<Response, NetworkError> {
        guard let sampleData = try? loadSampleData(request) else {
            fatalError("❌ Can't load data")
        }

        guard let statusCode = sampleData.statusCode,
              let url = request.url
        else {
            return Fail(error: NetworkError.unknown)
                .eraseToAnyPublisher()
        }

        guard let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: sampleData.responseHeaders
        ) else {
            return Fail(error: NetworkError.unknown)
                .eraseToAnyPublisher()
        }

        return Just((sampleData.responseBody ?? Data(), httpResponse))
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}

// MARK: Read data from assets

private extension SampleDataNetworking {
    func loadSampleData(_ request: URLRequest) throws -> EndpointRequestStorageModel? {
        guard let data = NSDataAsset(name: request.identifier, bundle: bundle)?.data else {
            return nil
        }

        return try decoder.decode(EndpointRequestStorageModel.self, from: data)
    }
}
