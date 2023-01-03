//
//  Requestable.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Endpoint definition

/// A type that represents an API endpoint.
public protocol Requestable: EndpointIdentifiable {
    /// The host URL of REST API.
    var baseURL: URL { get }

    /// The URL request path.
    var path: String { get }

    /// The request HTTP method.
    var method: HTTPMethod { get }

    /// The GET url parameters which are encoded into url.
    var urlParameters: [String: Any]? { get }

    /// The HTTP request headers.
    var headers: [String: String]? { get }

    /// The HTTP status codes which are allowed as acceptable for request.
    var acceptableStatusCodes: Range<HTTPStatusCode>? { get }

    /// The HTTP request body data type.
    var dataType: RequestDataType? { get }

    /// A Boolean flag indicating whether the request to the endpoint requires any type of authentication.
    var isAuthenticationRequired: Bool { get }
    
    /// A Boolean flag indicating whether the request provides token refreshing.
    var isRefreshTokenRequest: Bool { get }

    /// Encodes request body depending on requestable data type.
    /// - Returns: Encoded HTTP body.
    /// - Throws: An error if encoding fails.
    func encodeBody() throws -> Data?

    /// Creates `URLComponents` from endpoint definition.
    /// - Returns: URL components created based on baseURL, path and urlParameters.
    /// - Throws: ``RequestableError/invalidURLComponents``.
    func urlComponents() throws -> URLComponents
    
    /// Creates a `URLRequest` from endpoint definition.
    /// - Returns: URL request with all necessary info for successful response.
    /// - Throws: ``RequestableError`` in case the creating of URL from API endpoint fails.
    func asRequest() throws -> URLRequest
}
