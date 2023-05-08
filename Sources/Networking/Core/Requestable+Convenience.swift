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
    var urlParametersType: RequestUrlParametersType? {
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
        let urlPath = baseURL.appendingPathComponent(path)
        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: true) else {
            throw RequestableError.invalidURLComponents
        }

        // encode url parameters
        if let urlParametersType {
            urlComponents.queryItems = buildQueryItems(
                urlParameters: urlParametersType.parameters,
                arrayEncoding: urlParametersType.arrayEncoding
            )
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

// MARK: Private utils
private extension Requestable {
    func buildQueryItems(urlParameters: [String: Any], arrayEncoding: ArrayEncoding) -> [URLQueryItem] {
        urlParameters
            .map { key, value -> [URLQueryItem] in
                buildQueryItems(key: key, value: value, arrayEncoding: arrayEncoding)
            }
            .flatMap { $0 }
    }
    
    func buildQueryItems(key: String, value: Any, arrayEncoding: ArrayEncoding) -> [URLQueryItem] {
        if let values = value as? [Any] {
            var queryItems: [URLQueryItem] = []
            
            switch arrayEncoding {
            case .commaSeparated:
                queryItems = [URLQueryItem(
                    name: key,
                    value: values.map { String(describing: $0) }.joined(separator: ",")
                )]
                
            case .individual:
                for parameter in values {
                    queryItems.append(URLQueryItem(
                        name: key,
                        value: String(describing: parameter)
                    ))
                }
            }
            return queryItems
        }
        
        return [URLQueryItem(name: key, value: String(describing: value))]
    }
}
