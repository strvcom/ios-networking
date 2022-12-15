//
//  EndpointRequestStorageProcessor.swift
//  
//
//  Created by Matej Molnár on 12.12.2022.
//

import Foundation

#if os(watchOS)
    import os
#else
    import OSLog
#endif

// MARK: - Modifier storing endpoint requests

/// A response processor which stores all responses & related requests data into files.
///
/// The filename is created from a sessionId and a corresponding request identifier.
/// Stored files are stored under session folder and can be added to NSAssetCatalog and read via ``SampleDataNetworking`` to replay whole session.
open class EndpointRequestStorageProcessor: ResponseProcessing {
    private let fileManager: FileManager
    private let jsonEncoder: JSONEncoder

    private lazy var responsesDirectory = fileManager.temporaryDirectory.appendingPathComponent("responses")
    private lazy var requestCounter = Counter()

    public init(
        fileManager: FileManager = .default,
        jsonEncoder: JSONEncoder? = nil
    ) {
        self.fileManager = fileManager
        self.jsonEncoder = jsonEncoder ?? .default
    }
    
    /// Checks if session folder exists and eventually creates new one. Before storing file for response & related request data it checks the order of the endpoint request in session to allow replaying whole session.
    /// - Parameters:
    ///   - response: The response to be processed.
    ///   - request: The original URL request.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The original ``Response``.
    public func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response {
        storeResponse(response, endpointRequest: endpointRequest, urlRequest: urlRequest)
        return response
    }
}

// MARK: - Private storage extension

private extension EndpointRequestStorageProcessor {
    func storeResponse(
        _ response: Response,
        endpointRequest: EndpointRequest,
        urlRequest: URLRequest
    ) {
        Task(priority: .background) { [weak self] in
            guard let self = self else {
                return
            }

            self.createFolderIfNeeded(endpointRequest.sessionId)

            // for http responses read headers
            let httpResponse = response.response as? HTTPURLResponse
            let responseHeaders = httpResponse?.allHeaderFields as? [String: String]
            let statusCode = httpResponse?.statusCode

            let parameters: [String: String]? = {
                guard
                    let url = urlRequest.url,
                    let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                    let queryItems = urlComponents.queryItems?.sorted(by: { $0.name < $1.name })
                else {
                    return nil
                }
                
                return queryItems.reduce(into: [String: String]()) { dict, item in
                    dict[item.name] = item.value
                }
            }()


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
            await self.store(
                storageModel,
                url: self.createFileUrl(endpointRequest)
            )
        }
    }

    func createFolderIfNeeded(_ sessionId: String?) {
        do {
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

    func createFileUrl(_ endpointRequest: EndpointRequest) async -> URL {
        let count = await requestCounter.count(for: endpointRequest.endpoint.identifier)
        await requestCounter.increment(for: endpointRequest.endpoint.identifier)
        
        let fileName = "\(endpointRequest.sessionId)_\(endpointRequest.endpoint.identifier)_\(count)"

        return responsesDirectory
            .appendingPathComponent(endpointRequest.sessionId)
            .appendingPathComponent("\(fileName).json")
    }

    func store(_ model: EndpointRequestStorageModel, url: URL) {
        do {
            let jsonData = try jsonEncoder.encode(model)
            try jsonData.write(to: url)
            os_log("🎈 Response saved %{public}@ bytes at %{public}@", type: .info, "\(jsonData.count)", url.path)
        } catch {
            os_log("❌ Can't store response %{public}@ %{public}@ %{public}@", type: .error, model.method, model.path, error.localizedDescription)
        }
    }
}

// MARK: - JSONDecoder static extension

private extension JSONEncoder {
    /// A static JSONEncoder instance used by default implementation of APIManaging
    static let `default`: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
}
