//
//  LoggingInterceptor.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import Combine

public class LoggingInterceptor: RequestInterceptor {
    
    public init() {}
    
    public func adapt(_ requestPublisher: AnyPublisher<URLRequest, Error>, in apiCall: APICall) -> AnyPublisher<URLRequest, Error> {
        // log request
        requestPublisher
            .handleEvents(receiveOutput: { request in
                self.prettyRequestLog(request)
            })
            .catch({ error  -> AnyPublisher<URLRequest, Error> in
                self.prettyErrorLog(error, from: apiCall.endpoint)
                return requestPublisher
            })
            .eraseToAnyPublisher()
    }
    
    public func process(_ responsePublisher: AnyPublisher<Response, Error>, with request: URLRequest, in apiCall: APICall) -> AnyPublisher<Response, Error> {
        // log response
        responsePublisher
            .handleEvents(receiveOutput: { response in
                self.prettyResponseLog(response, from: apiCall.endpoint)
            })
            .catch({ error  -> AnyPublisher<Response, Error> in
                self.prettyErrorLog(error, from: apiCall.endpoint)
                return responsePublisher
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Private pretty logging
private extension LoggingInterceptor {
    func prettyRequestLog(_ request: URLRequest) {
        
        print("🔽🔽🔽 REQUEST  🔽🔽🔽")
        print("🔈 \(request.httpMethod ?? "Request method") \(request.url?.absoluteString ?? "URL")")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("👉 Headers: \(headers)")
        }
        if let body = request.httpBody, let stringBody = String(data: body, encoding: .utf8) {
            print("👉 Body: \(stringBody)")
        }
        print("🔼🔼🔼 REQUEST END 🔼🔼🔼")
    }
    
    func prettyResponseLog(_ response: Response, from endpoint: Requestable) {
        print("✅✅✅ RESPONSE ✅✅✅")
        if let httpResponse = response.response as? HTTPURLResponse {
            print("🔈 \(httpResponse.statusCode) \(endpoint.method.rawValue.uppercased()) \(httpResponse.url?.absoluteString ?? "URL")")
                
            if !httpResponse.allHeaderFields.isEmpty {
                if let date = httpResponse.allHeaderFields["Date"] {
                    print("👉 Date: \(date)")
                }
                if let server = httpResponse.allHeaderFields["Server"] {
                    print("👉 Server: \(server)")
                }
                if let contentType = httpResponse.allHeaderFields["Content-Type"] {
                    print("👉 Content-Type: \(contentType)")
                }
                if let contentLength = httpResponse.allHeaderFields["Content-Length"] {
                    print("👉 Content-Length: \(contentLength)")
                }
                if let connection = httpResponse.allHeaderFields["Connection"] {
                    print("👉 Connection: \(connection)")
                }
                if let body = String(data: response.data, encoding: .utf8) {
                    print("👉 Body: \(body)")
                }
            }
        }
        
        print("✅✅✅ RESPONSE END ✅✅✅")
    }
    
    func prettyErrorLog(_ error: Error, from endpoint: Requestable) {
        
        // retry error
        if let retriableError = error as? Retriable, retriableError.shouldRetry {
            print("⏬❎⏬ RETRY ⏬❎⏬")
            print("🔈 \(endpoint.method.rawValue.uppercased()) \(endpoint.path)")
            print("❌  Error: \(error.localizedDescription)")
            print("⏫❎⏫ RETRY END ⏫❎⏫")
        } else {
            
            // other errors
            print("❌❌❌ ERROR ❌❌❌")
            if let networkError = error as? NetworkError, case .unacceptableStatusCode(let statusCode, _, let response) = networkError {
                print("🔈 \(statusCode) \(endpoint.method.rawValue.uppercased()) \(endpoint.path)")
                
                if let body = String(data: response.data, encoding: .utf8) {
                    print("👉 Body: \(body)")
                }
            } else {
                print("🔈 \(endpoint.method.rawValue.uppercased()) \(endpoint.path)")
                print(error.localizedDescription)
            }
            print("❌❌❌ ERROR END ❌❌❌")
        }
    }
}
