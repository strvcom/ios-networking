//
//  EndpointRequestStorageProcessor.swift
//  STRV_template
//
//  Created by Tomas Cejka on 23.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Defines data model storing full endpoint request

public struct EndpointRequestStorageModel: Codable {
    let path: String
    let method: String
    let statusCode: Int?
    let requestBody: Data?
    let responseBody: Data?
    let requestHeaders: [String: String]?
    let responseHeaders: [String: String]?
}

// MARK: - Modifier storing endpoint requests

public class EndpointRequestStorageProcessor: ResponseProcessing {
    
    private lazy var fileManager: FileManager = FileManager.default
    private lazy var jsonEncoder: JSONEncoder = JSONEncoder()
    private lazy var responsesDirectory = fileManager.temporaryDirectory.appendingPathComponent("responses")
    
    public init() {
        createFolderIfNeeded()
    }
    
    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        
        responsePublisher
            .handleEvents(receiveOutput: { output in
                // for http responses read headers
                var responseHeaders: [String: String]?
                var statusCode: Int?
                
                if let httpResponse = output.response as? HTTPURLResponse {
                    responseHeaders = httpResponse.allHeaderFields as? [String: String]
                    statusCode = httpResponse.statusCode
                }
                // create data model & url
                let fileUrl = self.responsesDirectory.appendingPathComponent("\(endpointRequest.identifier).json")
                let storageModel = EndpointRequestStorageModel(
                    path: endpointRequest.endpoint.path,
                    method: endpointRequest.endpoint.method.rawValue,
                    statusCode: statusCode,
                    requestBody: urlRequest.httpBody,
                    responseBody: output.data,
                    requestHeaders: urlRequest.allHTTPHeaderFields,
                    responseHeaders: responseHeaders
                )
                self.store(storageModel, url: fileUrl)
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Private storage extension

private extension EndpointRequestStorageProcessor {
    func createFolderIfNeeded() {
        do {
            if !fileManager.fileExists(atPath: responsesDirectory.path) {
                try fileManager.createDirectory(atPath: responsesDirectory.path, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("❌ Can't create responses storage directory \(error.localizedDescription)")
        }
    }
    
    func store(_ model: EndpointRequestStorageModel, url: URL) {
        do {
            let jsonData = try jsonEncoder.encode(model)
            try jsonData.write(to: url)
            print("🎈 Saved \(jsonData.count) bytes at \(url.path)")
        } catch {
            print("❌ Can't store \(model.method) \(model.path) \(error.localizedDescription)")
        }
    }
    
}
