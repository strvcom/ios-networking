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
/// Stored files are stored under session folder and can be added to NSAssetCatalog and read via `SampleDataNetworking` to replay whole session.
open class EndpointRequestStorageProcessor: ResponseProcessing, ErrorProcessing {
    // MARK: Private variables
    private let fileManager: FileManager
    private let jsonEncoder: JSONEncoder
    private let fileDataWriter: FileDataWriting
    private let config: Config
    
    private lazy var responsesDirectory = fileManager.temporaryDirectory.appendingPathComponent("responses")
    private lazy var requestCounter = Counter()
    private lazy var multipeerConnectivityManager: MultipeerConnectivityManager? = {
        #if DEBUG
        // Initialise only in DEBUG mode otherwise it could pose a security risk for production apps.
        guard let multiPeerSharingConfig = config.multiPeerSharing else {
            return nil
        }
        
        let initialBuffer = multiPeerSharingConfig.shareHistory ? getAllStoredModels() : []
        return .init(buffer: initialBuffer)
        #else
        return nil
        #endif
    }()
    
    // MARK: Default shared instance
    public static let shared = EndpointRequestStorageProcessor(
        config: .init(
            multiPeerSharing: .init(shareHistory: true),
            storedSessionsLimit: 5
        )
    )
    
    public init(
        fileManager: FileManager = .default,
        fileDataWriter: FileDataWriting = FileDataWriter(),
        jsonEncoder: JSONEncoder? = nil,
        config: Config = .default
    ) {
        self.fileManager = fileManager
        self.fileDataWriter = fileDataWriter
        self.jsonEncoder = jsonEncoder ?? .default
        self.config = config

        deleteStoredSessionsExceedingLimit()
    }
    
    /// Stores the `Response` in file system on background thread and returns unmodified response.
    /// - Parameters:
    ///   - response: The response to be stored.
    ///   - request: The original URL request.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The original ``Response``.
    public func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response {
        storeResponse(response, endpointRequest: endpointRequest, urlRequest: urlRequest)
        return response
    }
    
    /// In case the error is `NetworkError` which includes `Response` it stores the response and returns the original `Error`.
    /// - Parameters:
    ///   - error: The error to be stored.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The original `Error`.
    public func process(_ error: Error, for endpointRequest: EndpointRequest) async -> Error {
        guard
            let error = error as? NetworkError,
            let urlRequest = try? endpointRequest.endpoint.asRequest()
        else {
            return error
        }
        
        switch error {
        case let .unacceptableStatusCode(_, _, response):
            storeResponse(response, endpointRequest: endpointRequest, urlRequest: urlRequest)
        case let .noStatusCode(response):
            storeResponse(response, endpointRequest: endpointRequest, urlRequest: urlRequest)
        case .headerIsInvalid, .underlying, .unknown:
            break
        }
        
        return error
    }
}

// MARK: - Config

public extension EndpointRequestStorageProcessor {
    struct Config {
        public static let `default` = Config()
        
        /// If `nil` the MultiPeerConnectivity session won't get initialised.
        let multiPeerSharing: MultiPeerSharingConfig?
        /// The maximum limit for how many sessions can be stored in the file system. All sessions exceeding the limit will be deleted.
        let storedSessionsLimit: Int
        
        public init(
            multiPeerSharing: MultiPeerSharingConfig? = nil,
            storedSessionsLimit: Int = 0
        ) {
            self.multiPeerSharing = multiPeerSharing
            self.storedSessionsLimit = storedSessionsLimit
        }
    }
    
    struct MultiPeerSharingConfig {
        /// If `true` it loads all stored responses and shares them at the start.
        /// If `false` it only shares the responses from the current session.
        let shareHistory: Bool
        
        public init(shareHistory: Bool) {
            self.shareHistory = shareHistory
        }
    }
}

// MARK: - Private storage extension

private extension EndpointRequestStorageProcessor {
    /// Checks if session folder exists and eventually creates a new one. Before storing file for response & related request data it checks the order of the endpoint request in session to allow replaying whole session.
    func storeResponse(
        _ response: Response,
        endpointRequest: EndpointRequest,
        urlRequest: URLRequest
    ) {
        Task.detached(priority: .background) { [weak self] in
            guard let self else {
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
                sessionId: endpointRequest.sessionId,
                date: Date(),
                path: endpointRequest.endpoint.path,
                parameters: parameters,
                method: endpointRequest.endpoint.method.rawValue,
                statusCode: statusCode,
                requestBody: urlRequest.httpBody,
                responseBody: response.data,
                requestHeaders: urlRequest.allHTTPHeaderFields,
                responseHeaders: responseHeaders
            )
            
            await self.store(
                storageModel,
                fileUrl: self.createFileUrl(endpointRequest)
            )
            
            multipeerConnectivityManager?.send(model: storageModel)
        }
    }

    func createFolderIfNeeded(_ sessionId: String?) {
        do {
            if let sessionId {
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

    func store(_ model: EndpointRequestStorageModel, fileUrl: URL) {
        do {
            let jsonData = try jsonEncoder.encode(model)
            try fileDataWriter.write(jsonData, to: fileUrl)
            os_log("🎈 Response saved %{public}@ bytes at %{public}@", type: .info, "\(jsonData.count)", fileUrl.path)
        } catch {
            os_log("❌ Can't store response %{public}@ %{public}@ %{public}@", type: .error, model.method, model.path, error.localizedDescription)
        }
    }
    
    /// Browses through the whole responseDirectory and maps every saved file to `EndpointRequestStorageModel`.
    func getAllStoredModels() -> [EndpointRequestStorageModel] {
        var models = [EndpointRequestStorageModel]()
        
        for sessionName in getAllStoredSessionNames() {
            let sessionDirectory = responsesDirectory.appendingPathComponent(sessionName)
            
            // Get names of all files inside sessionDirectory.
            guard let fileNames = try? fileManager.contentsOfDirectory(atPath: sessionDirectory.path) else {
                continue
            }
            
            // Map all files to models.
            for fileName in fileNames {
                guard
                    let data = try? Data(contentsOf: sessionDirectory.appendingPathComponent(fileName)),
                    let model = try? JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)
                else {
                    continue
                }
                
                models.append(model)
            }
        }
        
        return models
    }
    
    /// Get names of all subdirectories of responsesDirectory.
    func getAllStoredSessionNames() -> [String] {
        (try? fileManager.contentsOfDirectory(atPath: responsesDirectory.path)) ?? []
    }
    
    /// In case the number of stored sessions exceeds the maximum limit (from config) the function deletes the oldest stored sessions that don't fit into the limit.
    func deleteStoredSessionsExceedingLimit() {
        guard config.storedSessionsLimit > 0 else {
            return
        }
        
        let sessionNames = getAllStoredSessionNames()
        
        guard sessionNames.count > config.storedSessionsLimit else {
            return
        }
        
        let sessionNamesForDeletion = sessionNames
            // We can sort sessions from latest to oldest by the file names since the names are timestamps.
            .sorted { $0 > $1 }
            .dropFirst(config.storedSessionsLimit)
        
        for sessionName in sessionNamesForDeletion {
            let sessionDirectory = responsesDirectory.appendingPathComponent(sessionName)
            try? fileManager.removeItem(atPath: sessionDirectory.path)
        }
    }
}

// MARK: - JSONDecoder static extension

private extension JSONEncoder {
    /// A static JSONEncoder instance used by default implementation of APIManaging.
    static let `default`: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
}
