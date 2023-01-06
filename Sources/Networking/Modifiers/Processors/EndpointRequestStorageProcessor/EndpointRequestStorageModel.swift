//
//  EndpointRequestStorageModel.swift
//
//
//  Created by Tomas Cejka on 19.10.2021.
//

import Foundation

// MARK: - Defines data model storing full endpoint request

/// A model containing all necessary info about request and related response to be replayed as mocked data.
public struct EndpointRequestStorageModel: Codable {
    public let sessionId: String
    public let date: Date
    public let path: String
    public let parameters: [String: String]?
    public let method: String
    public let statusCode: Int?
    public let requestBody: Data?
    public let responseBody: Data?
    public let requestHeaders: [String: String]?
    public let responseHeaders: [String: String]?
    
    public var requestBodyString: String? {
        guard let requestBody else {
            return nil
        }
        
        return String(data: requestBody, encoding: .utf8)
    }
    
    public var responseBodyString: String? {
        guard let responseBody else {
            return nil
        }
        
        return String(data: responseBody, encoding: .utf8)
    }
}
