//
//  Requestablre.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Endpoint definition

public protocol Requestable: EndpointIdentifiable {
    var baseURL: URL { get }

    var path: String { get }

    var method: HTTPMethod { get }

    var urlParameters: [String: Any]? { get }

    var headers: [String: String]? { get }

    var acceptableStatusCodes: Range<HTTPStatusCode>? { get }

    var dataType: RequestDataType? { get }

    var isAuthenticationRequired: Bool { get }

    func encodeBody() throws -> Data?

    func asRequest() throws -> URLRequest
}
