//
//  MockResponseProvider.swift
//
//
//  Created by Matej Molnár on 04.01.2023.
//

import Foundation

// necessary for NSDataAsset import
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - MockResponseProvider definition

/// A response provider which creates responses for requests from corresponding data files stored in Assets.
@NetworkingActor
open class MockResponseProvider: ResponseProviding {
    private let bundle: Bundle
    private let sessionId: String
    private let requestCounter = Counter()
    private lazy var decoder = JSONDecoder()

    /// Creates MockResponseProvider instance.
    /// - Parameters:
    ///   - bundle: A bundle which includes the assets file.
    ///   - sessionId: An ID of a session, which data should be read.
    public init(with bundle: Bundle, sessionId: String) {
        self.bundle = bundle
        self.sessionId = sessionId
    }

    /// Creates a ``Response`` for a given `URLRequest` based on data from a corresponding file stored in Assets.
    /// - Parameter request: URL request.
    public func response(for request: URLRequest) async throws -> Response {
        guard let model = try? await loadModel(for: request) else {
            throw NetworkError.underlying(error: MockResponseProviderError.unableToLoadAssetData)
        }

        guard
            let statusCode = model.statusCode,
            let url = request.url,
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: model.responseHeaders
            )
        else {
            throw NetworkError.underlying(error: MockResponseProviderError.unableToConstructResponse)
        }
        
        return Response(model.responseBody ?? Data(), httpResponse)
    }
}

// MARK: Private helper functions

private extension MockResponseProvider {
    /// Loads a corresponding file from Assets for a given ``URLRequest`` and decodes the data to `EndpointRequestStorageModel`.
    func loadModel(for request: URLRequest) async throws -> EndpointRequestStorageModel? {
        // counting from 0, check storage request processing
        let count = requestCounter.count(for: request.identifier)

        if let data = NSDataAsset(name: "\(sessionId)_\(request.identifier)_\(count)", bundle: bundle)?.data {
            // store info about next indexed api call
            requestCounter.increment(for: request.identifier)
            return try decoder.decode(EndpointRequestStorageModel.self, from: data)
        }
        
        // return previous response, if no more stored indexed api calls
        // swiftlint:disable:next empty_count
        if count > 0, let data = NSDataAsset(name: "\(sessionId)_\(request.identifier)_\(count - 1)", bundle: bundle)?.data {
            return try decoder.decode(EndpointRequestStorageModel.self, from: data)
        }

        return nil
    }
}
