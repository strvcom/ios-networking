//
//  SampleDataNetworking.swift
//  Networking Tests
//
//  Created by Tomas Cejka on 07.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// For NSDataAsset import
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - SampleDataNetworking which reads data from stored files
/// ``Networking/Networking`` implementation reading data for request from `NSDataAsset` for injected sessionId
open class SampleDataNetworking: Networking {
    private let bundle: Bundle
    private let sessionId: String
    private lazy var requestCounter: [String: Int] = [:]
    private lazy var decoder = JSONDecoder()

    // need to inject bundle
    /// Creates sampleData networking
    /// - Parameters:
    ///   - bundle: bundle where is `NSDataAsset` localized
    ///   - sessionId: sessionId for session which data should be read
    public init(with bundle: Bundle, sessionId: String) {
        self.bundle = bundle
        self.sessionId = sessionId
    }

    /// Creates request publisher which returns ``Response`` loaded from files
    /// - Parameter request: URL request
    /// - Returns: publisher streaming ``Response`` for requests and injected sessionId
    public func request(for request: URLRequest) throws -> Response {
        guard let sampleData = try? loadSampleData(for: request) else {
            fatalError("❌ Can't load data")
        }

        guard
            let statusCode = sampleData.statusCode,
            let url = request.url
        else {
            throw NetworkError.unknown
        }

        guard
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: sampleData.responseHeaders
            )
        else {
            throw NetworkError.headerIsInvalid
        }

        return (sampleData.responseBody ?? Data(), httpResponse)
         
    }
}

// MARK: Read data from assets

private extension SampleDataNetworking {
    func loadSampleData(for request: URLRequest) throws -> EndpointRequestStorageModel? {
        // counting from 1, check storage request processing
        let count = requestCounter[request.identifier] ?? 1

        if let data = NSDataAsset(name: "\(sessionId)_\(request.identifier)_\(count)", bundle: bundle)?.data {
            // store info about next indexed api call
            requestCounter[request.identifier] = count + 1
            return try decoder.decode(EndpointRequestStorageModel.self, from: data)
        }
        // return previous response, if no more stored indexed api calls
        if count > 1, let data = NSDataAsset(name: "\(sessionId)_\(request.identifier)_\(count - 1)", bundle: bundle)?.data {
            return try decoder.decode(EndpointRequestStorageModel.self, from: data)
        }

        return nil
    }
}
