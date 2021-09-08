//
//  Requestable+Convenience.swift
//
//
//  Created by Tomas Cejka on 06.09.2021.
//

import Foundation

// MARK: - Default values for requestable

public extension Requestable {
    var method: HTTPMethod {
        .get
    }

    var isAuthenticationRequired: Bool {
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
}

// MARK: - Default implementation for requestable

public extension Requestable {
    // default implementation for encodable body
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

    func asRequest() throws -> URLRequest {
        // url creation
        let urlPath = baseURL.appendingPathComponent(path)
        guard var urlComponents = URLComponents(url: urlPath, resolvingAgainstBaseURL: false) else {
            throw RequestableError.invalidURLComponents
        }

        // encode url parameters
        if let urlParameters = urlParameters {
            urlComponents.queryItems = urlParameters.map { URLQueryItem(name: $0, value: String(describing: $1)) }
        }

        guard let url = urlComponents.url else {
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
