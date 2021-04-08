//
//  EndpointIdentifiable.swift
//  STRV_template
//
//  Created by Tomas Cejka on 08.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines attributes identifying endpoint

public protocol EndpointIdentifiable {
    var apiPath: String { get }
    var apiMethod: String { get }
}

// MARK: - Default implementation for endpoint identifiable

public extension Identifiable where Self: EndpointIdentifiable {
    var identifier: String {
        // solve potential doubled '_' when api path starting by '/'
        // first is path to have method like a divider to avoid ambiguity like users vs users_2
        var normalizedApiPath = apiPath
        if apiPath.starts(with: "/") {
            normalizedApiPath = String(apiPath.dropFirst())
        }

        return "\(normalizedApiPath.replacingOccurrences(of: "/", with: "_"))_\(apiMethod.lowercased())"
    }
}

// MARK: - Default implementation for URLRequest

extension URLRequest: EndpointIdentifiable, Identifiable {
    public var apiPath: String {
        url?.path ?? ""
    }

    public var apiMethod: String {
        httpMethod ?? ""
    }
}

// MARK: - Default implementation identifying endpoint

public extension Requestable where Self: EndpointIdentifiable {
    var apiPath: String {
        path
    }

    var apiMethod: String {
        method.rawValue
    }
}
