//
//  LoggingInterceptor.swift
//
//
//  Created by Matej Molnár on 01.12.2022.
//

import Foundation
#if os(watchOS)
    import os
#else
    import OSLog
#endif

// MARK: - Pretty logging modifier

/// ``RequestInterceptor`` which logs requests & responses info into console in pretty way
open class LoggingInterceptor: RequestInterceptor {
    // MARK: Default shared instance
    public static let shared = LoggingInterceptor()
    
    public init() {}

    /// Logs a given `URLRequest` into console.
    /// - Parameters:
    ///   - request: The request to be logged.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The the original `URLRequest`.
    public func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) -> URLRequest {
        prettyRequestLog(request, from: endpointRequest.endpoint)
        return request
    }

    /// Logs a given ``Response`` into console.
    /// - Parameters:
    ///   - response: The response to be logged.
    ///   - request: The original URL request.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The original ``Response``.
    public func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) throws -> Response {
        prettyResponseLog(response, from: endpointRequest.endpoint)
        return response
    }
    
    /// Logs a given `Error` into console.
    /// - Parameters:
    ///   - error: The error to be logged.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The original `Error`.
    public func process(_ error: Error, for endpointRequest: EndpointRequest) async -> Error {
        prettyErrorLog(error, from: endpointRequest.endpoint)
        return error
    }
}

// MARK: - Private pretty logging

private extension LoggingInterceptor {
    func prettyRequestLog(_ request: URLRequest, from endpoint: Requestable) {
        os_log("🔽🔽🔽 REQUEST  🔽🔽🔽", type: .info)
        os_log("🔈 %{public}@ %{public}@", type: .info, request.httpMethod ?? "Request method", request.url?.absoluteString ?? "URL")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            os_log("👉 Headers: %{public}@", type: .info, headers)
        }
        
        if
            let dataType = endpoint.dataType,
            case let RequestDataType.encodable(_, _, hideFromLogs) = dataType,
            hideFromLogs
        {
            os_log("👉 Body is hidden from logs, most likely due to including sensitive information", type: .info)
        } else if
            let requestBody = request.httpBody,
            let object = try? JSONSerialization.jsonObject(with: requestBody, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let body = String(data: data, encoding: .utf8) {
            os_log("👉 Body: %{public}@", type: .info, body)
        }
        
        os_log("🔼🔼🔼 REQUEST END 🔼🔼🔼", type: .info)
    }

    func prettyResponseLog(_ response: Response, from endpoint: Requestable) {
        os_log("✅✅✅ RESPONSE ✅✅✅", type: .info)
        if let httpResponse = response.response as? HTTPURLResponse {
            os_log("🔈 %{public}@ %{public}@ %{public}@", type: .info, "\(httpResponse.statusCode)", endpoint.method.rawValue.uppercased(), httpResponse.url?.absoluteString ?? "URL")

            if !httpResponse.allHeaderFields.isEmpty {
                if let date = httpResponse.allHeaderFields["Date"] as? String {
                    os_log("👉 Date: %{public}@", type: .info, date)
                }
                if let server = httpResponse.allHeaderFields["Server"] as? String {
                    os_log("👉 Server: %{public}@", type: .info, server)
                }
                if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                    os_log("👉 Content-Type: %{public}@", type: .info, contentType)
                }
                if let contentLength = httpResponse.allHeaderFields["Content-Length"] as? String {
                    os_log("👉 Content-Length: %{public}@", type: .info, contentLength)
                }
                if let connection = httpResponse.allHeaderFields["Connection"] as? String {
                    os_log("👉 Connection: %{public}@", type: .info, connection)
                }

                if let object = try? JSONSerialization.jsonObject(with: response.data, options: []),
                   let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
                   let body = String(data: data, encoding: .utf8)
                {
                    // swiftlint:disable:previous opening_brace
                    os_log("👉 Body: %{public}@", type: .info, body)
                }
            }
        }
        os_log("✅✅✅ RESPONSE END ✅✅✅", type: .info)
    }

    func prettyErrorLog(_ error: Error, from endpoint: Requestable) {
        os_log("❌❌❌ ERROR ❌❌❌", type: .error)
        if let networkError = error as? NetworkError, case let .unacceptableStatusCode(statusCode, _, response) = networkError {
            os_log("🔈 %{public}@ %{public}@ %{public}@", type: .error, String(statusCode), endpoint.method.rawValue.uppercased(), endpoint.path)

            if let body = String(data: response.data, encoding: .utf8) {
                os_log("👉 Body: %{public}@", type: .error, body)
            }
        } else {
            os_log("🔈 %{public}@ %{public}@", type: .error, endpoint.method.rawValue.uppercased(), endpoint.path)
            os_log("❌ %{public}@", type: .error, error.localizedDescription)
        }
        os_log("❌❌❌ ERROR END ❌❌❌", type: .error)
    }
}
