//
//  Requestable.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Endpoint definition

/// API endpoint definition
public protocol Requestable: EndpointIdentifiable {
    /// Host URL of REST API
    var baseURL: URL { get }

    /// URL request path
    var path: String { get }

    /// Request HTTP method
    var method: HTTPMethod { get }

    /// GET url parameters which are encoded into url
    var urlParameters: [String: Any]? { get }

    /// HTTP  request headers
    var headers: [String: String]? { get }

    /// HTTP status codes which are allowed as acceptable for request
    var acceptableStatusCodes: Range<HTTPStatusCode>? { get }

    /// HTTP request body data type
    var dataType: RequestDataType? { get }

    /// Boolean flag whether the request to the endpoint requires any type of authentication
    var isAuthenticationRequired: Bool { get }

    /// Method encodes request body depending on requestable data type
    /// - Returns: Encoded http body
    /// - Throws: An error if encoding fails
    func encodeBody() throws -> Data?

    /// Method creates URL request upon requestable variables
    /// - Returns: URL request with all necessary info for successful response
    /// - Throws: ``RequestableError`` in case creating URL from API endpoint fails
    func asRequest() throws -> URLRequest
}
