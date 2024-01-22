//
//  Requestable.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

/** A type that represents an API endpoint.

 By conforming to the ``Requestable`` protocol, you can define endpoint definitions containing the elementary HTTP request components necessary to create valid HTTP requests.
 <br>**Recommendation:** Follow the `Router` naming convention to explicitly indicate the usage of a router pattern.

 ### Example
 ```swift
 enum UserRouter {
     case getUser
     case updateUser(UpdateUserRequest)
 }

 extension UserRouter: Requestable {
     // The base URL address used for the HTTP call.
     var baseURL: URL {
         URL(string: Constants.baseHost)!
     }

     // Path will be appended to the base URL.
     var path: String {
         switch self {
         case .getUser, .updateUser:
             return "/user"
         }
     }

     // HTTPMethod used for each endpoint.
     var method: HTTPMethod {
         switch self {
         case .getUser:
             return .get
         case .updateUser:
             return .post
         }
     }

     // Optional body data encoded in JSON by default.
     var dataType: RequestDataType? {
         switch self {
         case .getUser:
             return nil
         case let .updateUser(data):
             return .encodable(data)
         }
     }

     // Optional authentication requirement if AuthorizationInterceptor is used.
     var isAuthenticationRequired: Bool {
         switch self {
         case .getUser, .updateUser:
             return true
         }
     }
 }
 ```

 Some of the properties have default implementations defined in the `Requestable+Convenience` extension.
*/

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
