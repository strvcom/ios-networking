//
//  Requestable+Convenience.swift
//
//
//  Created by Tomas Cejka on 06.09.2021.
//

import Foundation

// MARK: - Default values for requestable

/// Default values for convenience.
public extension Requestable {
    /// The default value is ``HTTPMethod/get``.
    var method: HTTPMethod {
        .get
    }
    
    /// By default the requestable API endpoint is unauthenticated.
    var isAuthenticationRequired: Bool {
        false
    }
    
    /// The default value is `nil`.
    var headers: [String: String]? {
        nil
    }
    
    /// The default value is `nil`.
    var urlParameters: [String: Any]? {
        nil
    }
    
    /// The default value is success & redirect http codes 200-399.
    var acceptableStatusCodes: Range<HTTPStatusCode>? {
        HTTPStatusCode.successAndRedirectCodes
    }
    
    /// The default value is `nil`.
    var dataType: RequestDataType? {
        nil
    }
}

// MARK: - Default implementation for requestable

/// Default methods implementation for convenience.
public extension Requestable {
    func urlComponents() throws -> URLComponents {
        // url creation
        let urlPath = path.isEmpty ? baseURL : baseURL.appendingPathComponent(path)
        
        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else {
            throw RequestableError.invalidURLComponents
        }
        
        // encode url parameters
        if let urlParameters {
            urlComponents.percentEncodedQueryItems = buildPercentEncodedQueryItems(urlParameters: urlParameters)
        }
        
        return urlComponents
    }
    
    func encodeBody() throws -> Data? {
        guard let dataType else {
            return nil
        }
        
        switch dataType {
        case let .encodable(encodable, jsonEncoder, _):
            return try jsonEncoder.encode(encodable)
        case let .custom(data, _):
            return data
        }
    }
    
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

// MARK: Build Query Items
private extension Requestable {
    func buildPercentEncodedQueryItems(urlParameters: [String: Any]) -> [URLQueryItem] {
        urlParameters
            .map { key, value -> [URLQueryItem] in
                buildPercentEncodedQueryItem(key: key, value: value)
            }
            .flatMap { $0 }
    }
    
    func buildPercentEncodedQueryItem(key: String, value: Any) -> [URLQueryItem] {
        switch value {
        case let parameter as ArrayParameter:
            return buildArrayParameter(
                key: key,
                parameter: parameter
            )
            
        case let parameter as CustomEncodedParameter:
            return [URLQueryItem(name: key, value: parameter.encodedValue)]
            
        default:
            return [
                URLQueryItem(name: key, value: String(describing: value))
                    .percentEncoded()
            ]
        }
    }
    
    func buildArrayParameter(
        key: String,
        parameter: ArrayParameter
    ) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        
        switch parameter.arrayEncoding {
        case .commaSeparated:
            queryItems = [
                URLQueryItem(
                    name: key,
                    value: parameter.values
                        .map { String(describing: $0) }
                        .joined(separator: ",")
                )
                .percentEncoded()
            ]
            
        case .individual:
            for parameter in parameter.values {
                queryItems.append(
                    URLQueryItem(
                        name: key,
                        value: String(describing: parameter)
                    )
                    .percentEncoded()
                )
            }
        }
        return queryItems
    }
}
