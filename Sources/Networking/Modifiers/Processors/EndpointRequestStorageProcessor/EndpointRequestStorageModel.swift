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
    public let date: Date
    public let path: String
    public let parameters: [String: String]?
    public let method: String
    public let statusCode: Int?
    public let requestBody: Data?
    public let requestBodyString: String?
    public let responseBody: Data?
    public let responseBodyString: String?
    public let requestHeaders: [String: String]?
    public let responseHeaders: [String: String]?
}
