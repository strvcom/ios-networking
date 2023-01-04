//
//  SampleResponseProvider.swift
//  
//
//  Created by Matej Molnár on 04.01.2023.
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
public class SampleResponseProvider: ResponseProviding {
    private let bundle: Bundle
    private let sessionId: String
    private var requestCounter = Counter()
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
    ///
    public func response(for request: URLRequest) async throws -> Response {
        guard let model = try? await loadModel(for: request) else {
            fatalError("❌ Can't load data")
        }

        guard
            let statusCode = model.statusCode,
            let url = request.url
        else {
            throw NetworkError.unknown//noStatusCode(response: <#T##Response#>)
        }

        guard
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: model.responseHeaders
            )
        else {
            throw NetworkError.unknown
        }

        return Response(model.responseBody ?? Data(), httpResponse)
    }
}

// MARK: Read data from assets

private extension SampleResponseProvider {
    func loadModel(for request: URLRequest) async throws -> EndpointRequestStorageModel? {
        // counting from 1, check storage request processing
        let count = await requestCounter.count(for: request.identifier)

        if let data = NSDataAsset(name: "\(sessionId)_\(request.identifier)_\(count)", bundle: bundle)?.data {
            // store info about next indexed api call
            await requestCounter.increment(for: request.identifier)
            return try decoder.decode(EndpointRequestStorageModel.self, from: data)
        }
        
        // return previous response, if no more stored indexed api calls
        if count > 0, let data = NSDataAsset(name: "\(sessionId)_\(request.identifier)_\(count - 1)", bundle: bundle)?.data {
            return try decoder.decode(EndpointRequestStorageModel.self, from: data)
        }

        return nil
    }
}
