//
//  SampleDataManager.swift
//
//
//  Created by Tomas Cejka on 11.10.2021.
//

import Combine
import Foundation

// For NSDataAsset import
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - SampleDataManager allows to read response from files

open class SampleDataManager {
    private let bundle: Bundle
    private let sessionId: String
    private lazy var sampleDataModels: [String: [EndpointRequestStorageModel]] = [:]
    private lazy var decoder = JSONDecoder()

    // need to inject bundle
    public init(with bundle: Bundle, sessionId: String) {
        self.bundle = bundle
        self.sessionId = sessionId
    }

    public func sampleData(for request: URLRequest, with statusCode: HTTPStatusCode) -> EndpointRequestStorageModel? {
        if sampleDataModels[request.identifier] == nil {
            sampleDataModels[request.identifier] = []
        }

        loadSampleData(for: request)

        return sampleDataModels[request.identifier]?.first { $0.statusCode == statusCode }
    }

    public func sampleData(for request: URLRequest, with statusCode: HTTPStatusCode) -> Response? {
        guard
            let sampleData: EndpointRequestStorageModel = sampleData(for: request, with: statusCode),
            let url = request.url,
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: sampleData.responseHeaders
            )
        else {
            return nil
        }

        return (sampleData.responseBody ?? Data(), httpResponse)
    }
}

// MARK: - Read data from assets

private extension SampleDataManager {
    func loadSampleData(for request: URLRequest) {
        var count = 1
        while let data = NSDataAsset(name: "\(sessionId)_\(request.identifier)_\(count)", bundle: bundle)?.data {
            count += 1
            if let sampleDataModel = try? decoder.decode(EndpointRequestStorageModel.self, from: data) {
                sampleDataModels[request.identifier]?.append(sampleDataModel)
            }
        }
    }
}
