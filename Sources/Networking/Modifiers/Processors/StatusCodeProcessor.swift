//
//  StatusCodeProcessor.swift
//
//
//  Created by Matej Molnár on 01.12.2022.
//

import Foundation

/** A response processor validating ``Response`` http status code against ``Requestable`` API endpoint definition.

 Each ``Requestable`` endpoint definition contains a ``Requestable/acceptableStatusCodes`` range of acceptable status codes. By default, these are set to `200..<400`. This processor makes sure that the received response's HTTP code is an acceptable one, otherwise an ``NetworkError/unacceptableStatusCode(statusCode:acceptedStatusCodes:response:)`` error is thrown.

 In a typical usage you want to inject the shared instance as the first response processor to every instance of any type of APIManager.
 ```swift
 APIManager(
     //
     requestAdapters: [...],
     responseProcessors: [StatusCodeProcessor.shared, ...],
     errorProcessors: [...]
     //
 )
 ```
 */
open class StatusCodeProcessor: ResponseProcessing {
    public static let shared = StatusCodeProcessor()
    
    public init() {}
    
    /// Processes ``Response`` and throws ``NetworkError/unacceptableStatusCode(statusCode:acceptedStatusCodes:response:)`` in case status code is not contained in allowed status codes or ``NetworkError/noStatusCode(response:)`` if status code is missing in response, when validation successes processor passes original response value.
    /// - Parameters:
    ///   - response: The response to be processed.
    ///   - request: The original URL request.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The original response after status code validation.
    public func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) throws -> Response {
        guard let httpResponse = response.response as? HTTPURLResponse else {
            throw NetworkError.noStatusCode(response: response)
        }
        
        if
            let acceptableStatusCodes = endpointRequest.endpoint.acceptableStatusCodes,
            !acceptableStatusCodes.contains(httpResponse.statusCode)
        {
            throw NetworkError.unacceptableStatusCode(
                statusCode: httpResponse.statusCode,
                acceptedStatusCodes: acceptableStatusCodes,
                response: response
            )
        }
        
        return response
    }
}
