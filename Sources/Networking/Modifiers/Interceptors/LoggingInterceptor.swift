//
//  LoggingInterceptor.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation
#if os(watchOS)
    import os
#else
    import OSLog
#endif

// MARK: - Pretty logging modifier

open class LoggingInterceptor: RequestInterceptor {
    public init() {}

    public func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, for endpointRequest: EndpointRequest) -> AnyPublisher<URLRequest, Error> {
        // log request
        requestPublisher
            .handleEvents(receiveOutput: { request in
                self.prettyRequestLog(request)
            })
            .catch { error -> AnyPublisher<URLRequest, Error> in
                self.prettyErrorLog(error, from: endpointRequest.endpoint)
                return requestPublisher
            }
            .eraseToAnyPublisher()
    }

    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with _: URLRequest, for endpointRequest: EndpointRequest) -> AnyPublisher<Response, Error> {
        // log response
        responsePublisher
            .handleEvents(receiveOutput: { response in
                self.prettyResponseLog(response, from: endpointRequest.endpoint)
            })
            .catch { error -> AnyPublisher<Response, Error> in
                self.prettyErrorLog(error, from: endpointRequest.endpoint)
                return responsePublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private pretty logging

private extension LoggingInterceptor {
    func prettyRequestLog(_ request: URLRequest) {
        os_log("🔽🔽🔽 REQUEST  🔽🔽🔽", type: .info)
        os_log("🔈 %{public}@ %{public}@", type: .info, request.httpMethod ?? "Request method", request.url?.absoluteString ?? "URL")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            os_log("👉 Headers: %{public}@", type: .info, headers)
        }
        if let requestBody = request.httpBody, let object = try? JSONSerialization.jsonObject(with: requestBody, options: []),
           let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
           let body = String(data: data, encoding: .utf8)
        {
            // swiftlint:disable:previous opening_brace
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
        // retry error
        if let retryingError = error as? Retrying, retryingError.shouldRetry {
            os_log("⏬❎⏬ RETRY ⏬❎⏬", type: .debug)
            os_log("🔈 %{public}@ %{public}@", type: .debug, endpoint.method.rawValue.uppercased(), endpoint.path)
            os_log("❌  Error: %{public}@", type: .debug, error.localizedDescription)
            os_log("⏫❎⏫ RETRY END ⏫❎⏫", type: .debug)
        } else {
            // other errors
            os_log("❌❌❌ ERROR ❌❌❌", type: .error)
            if let networkError = error as? NetworkError, case let .unacceptableStatusCode(statusCode, _, response) = networkError {
                os_log("🔈 %{public}@ %{public}@ %{public}@", type: .error, statusCode, endpoint.method.rawValue.uppercased(), endpoint.path)

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
}
