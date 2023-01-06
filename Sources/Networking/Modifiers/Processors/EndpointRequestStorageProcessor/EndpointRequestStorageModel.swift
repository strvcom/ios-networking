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
    let sessionId: String
    let date: Date
    let path: String
    let parameters: [String: String]?
    let method: String
    let statusCode: Int?
    let requestBody: Data?
    let responseBody: Data?
    let requestHeaders: [String: String]?
    let responseHeaders: [String: String]?
    
    var requestBodyString: String? {
        guard let requestBody else {
            return nil
        }
        
        return String(data: requestBody, encoding: .utf8)
    }
    
    var responseBodyString: String? {
        guard let responseBody else {
            return nil
        }
        
        return String(data: responseBody, encoding: .utf8)
    }
}
