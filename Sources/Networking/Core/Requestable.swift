//
//  Requestablre.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Endpoint definition

public protocol Requestable: Identifiable, EndpointIdentifiable {
    var baseURL: URL { get }

    var path: String { get }

    var method: HTTPMethod { get }

    var urlParameters: [String: Any]? { get }

    var headers: [String: String]? { get }

    var acceptableStatusCodes: Range<HTTPStatusCode>? { get }

    var dataType: RequestDataType? { get }

    var authenticated: Bool { get }

    func encodeBody() throws -> Data?

    func asRequest() throws -> URLRequest
}

// MARK: - Default values

public extension Requestable {
    var method: HTTPMethod {
        .get
    }

    var authenticated: Bool {
        false
    }

    var headers: [String: String]? {
        nil
    }

    var urlParameters: [String: Any]? {
        nil
    }

    var acceptableStatusCodes: Range<HTTPStatusCode>? {
        HTTPStatusCode.successAndRedirectCodes
    }

    var dataType: RequestDataType? {
        nil
    }

    // default implementation for encodable body
    func encodeBody() throws -> Data? {
        guard let dataType = dataType else {
            return nil
        }
        switch dataType {
        case let .encodable(encodable):
            let anyEncodable = AnyEncodable(encodable)
            let jsonEncoder = JSONEncoder()
            return try jsonEncoder.encode(anyEncodable)
        default:
            break
        }

        return nil
    }

    func asRequest() throws -> URLRequest {
        // url creation
        let urlPath = baseURL.appendingPathComponent(path)
        guard let urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: false) else {
            throw RequestableError.invalidURLComponents
        }
        var mutableComponents = urlComponents
        // encode url parameters
        if let urlParameters = urlParameters {
            mutableComponents.queryItems = urlParameters.map { URLQueryItem(name: $0, value: String(describing: $1)) }
        }

        guard let url = mutableComponents.url else {
            throw RequestableError.invalidURLComponents
        }

        // request setup
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = try encodeBody()

        // content type
        switch dataType {
        case .encodable:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        default:
            break
        }

        return request
    }
}
