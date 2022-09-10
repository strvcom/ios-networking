//
//  Requestable+Convenience.swift
//
//
//  Created by Tomas Cejka on 06.09.2021.
//

import Foundation

// MARK: - Default values for requestable

/// Default values for convenience
public extension Requestable {
    /// Default value is ``HTTPMethod/get``
    var method: HTTPMethod {
        .get
    }

    /// By default is requestable API endpoint unauthenticated, default value is `value`
    var isAuthenticationRequired: Bool {
        false
    }

    /// Default value is `nil`
    var headers: [String: String]? {
        nil
    }

    /// Default value is `nil`
    var urlParameters: [String: Any]? {
        nil
    }

    /// Default value is success & redirect http codes 200-399
    var acceptableStatusCodes: Range<HTTPStatusCode>? {
        HTTPStatusCode.successAndRedirectCodes
    }

    /// Default value is `nil`
    var dataType: RequestDataType? {
        nil
    }
}

// MARK: - Default implementation for requestable

/// Default methods implementation for convenience
public extension Requestable {
    /// Depending on data type encodes body
    /// - Returns: Encoded body data
    func encodeBody() throws -> Data? {
        guard let dataType = dataType else {
            return nil
        }
        switch dataType {
        case let .encodable(encodable, jsonEncoder):
            let anyEncodable = AnyEncodable(encodable)
            return try jsonEncoder.encode(anyEncodable)
        case let .custom(data, _):
            return data
        }
    }

    /// Creates URLComponents from endpoint definition
    /// - Returns: URLComponents created from endpoint. Depending on baseURL, path and urlParameters.
    func urlComponents() throws -> URLComponents {
        // url creation
        let urlPath = baseURL.appendingPathComponent(path)
        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: false) else {
            throw RequestableError.invalidURLComponents
        }

        // encode url parameters
        if let urlParameters = urlParameters {
            urlComponents.queryItems = urlParameters.map { URLQueryItem(name: $0, value: String(describing: $1)) }
        }
        
        return urlComponents
    }
    
    /// Creates URLRequest from endpoint definition
    /// - Returns: URLRequest created from endpoint. Depending on type request has headers, get parameters or body data set.
    func asRequest() throws -> URLRequest {
        guard let url = try urlComponents().url else {
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
            request.setValue(
                HTTPHeader.ContentTypeValue.json.rawValue,
                forHTTPHeaderField: HTTPHeader.HeaderField.contentType.rawValue
            )
        case let .custom(_, contentType):
            request.setValue(
                contentType,
                forHTTPHeaderField: HTTPHeader.HeaderField.contentType.rawValue
            )
        default:
            break
        }

        return request
    }
}
