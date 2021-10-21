//
//  EndpointIdentifiable.swift
//  Networking
//
//  Created by Tomas Cejka on 08.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines attributes identifying endpoint

/// To be able to have unique identifier for both ``Requestable`` and `URLRequest` which is necessary to load correct sample data from file system
public protocol EndpointIdentifiable: Identifiable {
    /// All components which are used for unique identifier, typically URL path, HTTP method, GET parameters etc
    var identifiableComponents: [String] { get }
}

// MARK: - Default implementation for endpoint identifiable

public extension Identifiable where Self: EndpointIdentifiable {
    /// By default endpointIdentifiable creates its identifier from `identifiableComponents` which are sorted, lowercased and joined by '\_' to avoid any issues matching identifiers
    var identifier: String {
        identifiableComponents.filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .joined(separator: "_")
    }
}

// MARK: - Default implementation for URLRequest

extension URLRequest: EndpointIdentifiable {
    /// Identifiable components from `URLRequest`
    public var identifiableComponents: [String] {
        var components: [String] = []

        if let url = url, let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            // add path parts
            let pathComponents = urlComponents.path
                .split(separator: "/")
                .filter { !$0.isEmpty }
                .map { String($0) }
            components.append(contentsOf: pathComponents)

            let sortedQueryItems = urlComponents.queryItems?.sorted(by: { $0.name < $1.name })
            // add query items
            if let queryItems = sortedQueryItems {
                let mappedQueryItems = queryItems.flatMap { [$0.name, $0.value ?? ""] }
                components.append(contentsOf: mappedQueryItems)
            }

            // add method
            components.append(httpMethod ?? "")
        }

        return components
    }
}

// MARK: - Default implementation identifying endpoint

public extension Requestable {
    /// Identifiable components from ``Requestable``
    var identifiableComponents: [String] {
        var components: [String] = []

        // add path parts
        let pathComponents = path
            .split(separator: "/")
            .filter { !$0.isEmpty }
            .map { String($0) }
        components.append(contentsOf: pathComponents)

        let sortedParameters = urlParameters?.sorted(by: { $0.key < $1.key })
        // add parameters
        if let urlParameters = sortedParameters {
            let mappedParameters = urlParameters.flatMap { [$0.key, "\($0.value)"] }
            components.append(contentsOf: mappedParameters)
        }

        // add method
        components.append(method.rawValue)

        return components
    }
}
