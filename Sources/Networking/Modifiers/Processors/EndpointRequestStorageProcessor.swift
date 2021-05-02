//
//  EndpointRequestStorageProcessor.swift
//  STRV_template
//
//  Created by Tomas Cejka on 23.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation
import OSLog

// MARK: - Defines data model storing full endpoint request

public struct EndpointRequestStorageModel: Codable {
    public let date: Date
    public let path: String
    public let parameters: [String: String]?
    public let method: String
    public let statusCode: Int?
    public let requestBody: Data?
    public let responseBody: Data?
    public let requestHeaders: [String: String]?
    public let responseHeaders: [String: String]?
}

// MARK: - Modifier storing endpoint requests

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

    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        responsePublisher
            .handleEvents(receiveOutput: { [weak self] output in
                guard let self = self else {
                    return
                }
                self.backgroundQueue.async {
                    self.createFolderIfNeeded(endpointRequest.sessionId)

                    // for http responses read headers
                    var responseHeaders: [String: String]?
                    var statusCode: Int?

                    if let httpResponse = output.response as? HTTPURLResponse {
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
                        responseBody: output.data,
                        requestHeaders: urlRequest.allHTTPHeaderFields,
                        responseHeaders: responseHeaders
                    )
                    self.store(storageModel, url: self.createFileUrl(endpointRequest))
                }
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Private storage extension

private extension EndpointRequestStorageProcessor {
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
        if let sessionId = endpointRequest.sessionId {
            requestDirectory = requestDirectory.appendingPathComponent(sessionId)
            fileName = "\(sessionId)_\(endpointRequest.endpoint.identifier)"
        }

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
