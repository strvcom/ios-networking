//
//  APIStorageProcessor.swift
//  STRV_template
//
//  Created by Tomas Cejka on 23.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine


struct APIStorageModel: Codable {
    let path: String
    let method: String
    let statusCode: Int?
    let requestBody: Data?
    let responseBody: Data?
    let requestHeaders: [String: String]?
    let responseHeaders: [String: String]?
}

// Storing responses with all metadata
public class APIStorageProcessor: ResponseProcessing {
    
    private lazy var fileManager: FileManager = FileManager.default
    private lazy var jsonEncoder: JSONEncoder = JSONEncoder()
    private lazy var responsesDirectory = fileManager.temporaryDirectory.appendingPathComponent("responses")
    
    public init() {
        createFolderIfNeeded()
    }
    
    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with request: URLRequest, in apiCall: APICall) -> AnyPublisher<Response, Error> {
        
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
                let fileUrl = self.responsesDirectory.appendingPathComponent("\(apiCall.identifier).json")
                let storageModel = APIStorageModel(
                    path: apiCall.endpoint.path,
                    method: apiCall.endpoint.method.rawValue,
                    statusCode: statusCode,
                    requestBody: request.httpBody,
                    responseBody: output.data,
                    requestHeaders: request.allHTTPHeaderFields,
                    responseHeaders: responseHeaders
                )
                self.store(storageModel, url: fileUrl)
            })
            .eraseToAnyPublisher()
    }
}

private extension APIStorageProcessor {
    func createFolderIfNeeded() {
        do {
            if !fileManager.fileExists(atPath: responsesDirectory.path) {
                try fileManager.createDirectory(atPath: responsesDirectory.path, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("❌ Can't create responses storage directory \(error.localizedDescription)")
        }
    }
    
    func store(_ model: APIStorageModel, url: URL) {
        do {
            let jsonData = try jsonEncoder.encode(model)
            try jsonData.write(to: url)
            print("🎈 Saved \(jsonData.count) bytes at \(url.path)")
        } catch {
            print("❌ Can't store \(model.method) \(model.path) \(error.localizedDescription)")
        }
    }
    
}
