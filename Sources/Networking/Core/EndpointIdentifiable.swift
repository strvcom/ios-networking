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
    var identifiableComponents: [String] { get }
}

// MARK: - Default implementation for endpoint identifiable

public extension Identifiable where Self: EndpointIdentifiable {
    var identifier: String {
//        // solve potential doubled '_' when api path starting by '/'
//        // first is path to have method like a divider to avoid ambiguity like users vs users_2
//        var normalizedApiPath = apiPath
//        if apiPath.starts(with: "/") {
//            normalizedApiPath = String(apiPath.dropFirst())
//        }
//
//        return "\(normalizedApiPath.replacingOccurrences(of: "/", with: "_"))_\(apiMethod.lowercased())"
        identifiableComponents.filter { !$0.isEmpty }.map { $0.lowercased() }.joined(separator: "_")
    }
}

// MARK: - Default implementation for URLRequest

extension URLRequest: EndpointIdentifiable, Identifiable {
    public var identifiableComponents: [String] {
        var components: [String] = []

        if let url = url, let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            // add path parts
            let pathComponents = urlComponents.path.split(separator: "/").filter { !$0.isEmpty }.map { String($0) }
            components.append(contentsOf: pathComponents)

            // add query items
            if let queryItems = urlComponents.queryItems {
                components.append(contentsOf: queryItems.flatMap { [$0.name, $0.value ?? ""] })
            }

            // add method
            components.append(httpMethod ?? "")
        }

        return components
    }
}

// MARK: - Default implementation identifying endpoint

public extension Requestable where Self: EndpointIdentifiable {
    var identifiableComponents: [String] {
        var components: [String] = []

        // add path parts
        let pathComponents = path.split(separator: "/").filter { !$0.isEmpty }.map { String($0) }
        components.append(contentsOf: pathComponents)

        // add parameters
        if let urlParameters = urlParameters {
            components.append(contentsOf: urlParameters.flatMap { [$0.key, "\($0.value)"] })
        }

        // add method
        components.append(method.rawValue)

        return components
    }
}
