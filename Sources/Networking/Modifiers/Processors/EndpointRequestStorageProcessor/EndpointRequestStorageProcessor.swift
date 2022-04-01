//
//  EndpointRequestStorageProcessor.swift
//  Networking
//
//  Created by Tomas Cejka on 23.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

#if os(watchOS)
    import os
#else
    import OSLog
#endif

// MARK: - Modifier storing endpoint requests

/// Response processor which stores all responses & related requests data into files
/// Filename is created from sessionId and request identifier
/// Stored files are stored under session folder and can be added to NSAssetCatalog and read via ``SampleDataNetworking`` to replay whole session
open class EndpointRequestStorageProcessor: ResponseProcessing {
    private lazy var fileManager = FileManager.default
    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    private lazy var responsesDirectory = fileManager.temporaryDirectory.appendingPathComponent("responses")
    private lazy var backgroundQueue = DispatchQueue(label: "com.strv.requeststorage")
    private lazy var requestCounter: [String: Int] = [:]

    public init() {}

    /// Process checks if session folder exists and eventually creates new one. Before storing file for response & related request it checks order of the endpoint request in session to allow replaying whole session
    /// - Parameters:
    ///   - responsePublisher: original response publisher
    ///   - urlRequest: related URL request
    ///   - endpointRequest: endpoint request wrapper
    /// - Returns: Modified publisher which tries to store data into files
    public func process(_ responsePublisher: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> Response {
        responsePublisher
    }
}

// MARK: - Private storage extension

private extension EndpointRequestStorageProcessor {
    func storeResponse(
        _ response: Response,
        endpointRequest: EndpointRequest,
        urlRequest: URLRequest
    ) {
        backgroundQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.createFolderIfNeeded(endpointRequest.sessionId)

            // for http responses read headers
            var responseHeaders: [String: String]?
            var statusCode: Int?

            if let httpResponse = response.response as? HTTPURLResponse {
                responseHeaders = httpResponse.allHeaderFields as? [String: String]
                statusCode = httpResponse.statusCode
            }

            // parameters
            var parameters: [String: String]?
            if let url = urlRequest.url,
               let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = urlComponents.queryItems?.sorted(by: { $0.name < $1.name })
            {
                // swiftlint:disable:previous opening_brace
                parameters = queryItems.reduce(into: [String: String]()) { dict, item in
                    dict[item.name] = item.value
                }
            }

            // create data model
            let storageModel = EndpointRequestStorageModel(
                date: Date(),
                path: endpointRequest.endpoint.path,
                parameters: parameters,
                method: endpointRequest.endpoint.method.rawValue,
                statusCode: statusCode,
                requestBody: urlRequest.httpBody,
                requestBodyString: String(data: urlRequest.httpBody ?? Data(), encoding: .utf8),
                responseBody: response.data,
                responseBodyString: String(data: response.data, encoding: .utf8),
                requestHeaders: urlRequest.allHTTPHeaderFields,
                responseHeaders: responseHeaders
            )
            self.store(
                storageModel,
                url: self.createFileUrl(endpointRequest)
            )
        }
    }

    func createFolderIfNeeded(_ sessionId: String?) {
        do {
            // root storage folder
            if !fileManager.fileExists(atPath: responsesDirectory.path) {
                try fileManager.createDirectory(atPath: responsesDirectory.path, withIntermediateDirectories: true, attributes: nil)
            }

            // session folder
            if let sessionId = sessionId {
                let sessionDirectory = responsesDirectory.appendingPathComponent(sessionId)
                if !fileManager.fileExists(atPath: sessionDirectory.path) {
                    try fileManager.createDirectory(atPath: sessionDirectory.path, withIntermediateDirectories: true, attributes: nil)
                }
            }
        } catch {
            os_log("❌ Can't create responses storage directory %{public}@", type: .error, error.localizedDescription)
        }
    }

    func createFileUrl(_ endpointRequest: EndpointRequest) -> URL {
        var requestDirectory = responsesDirectory
        var fileName = endpointRequest.endpoint.identifier
        requestDirectory = requestDirectory.appendingPathComponent(endpointRequest.sessionId)
        fileName = "\(endpointRequest.sessionId)_\(endpointRequest.endpoint.identifier)"

        let count = requestCounter[endpointRequest.endpoint.identifier] ?? 1
        fileName = fileName.appending("_\(count)")
        requestCounter[endpointRequest.endpoint.identifier] = count + 1

        return requestDirectory.appendingPathComponent("\(fileName).json")
    }

    func store(_ model: EndpointRequestStorageModel, url: URL) {
        do {
            let jsonData = try jsonEncoder.encode(model)
            try jsonData.write(to: url)
            os_log("🎈 Saved %{public}@ bytes at %{public}@", type: .info, "\(jsonData.count)", url.path)
        } catch {
            os_log("❌ Can't store %{public}@ %{public}@ %{public}@", type: .error, model.method, model.path, error.localizedDescription)
        }
    }
}
