//
//  EndpointIdentifiable.swift
//  STRV_template
//
//  Created by Tomas Cejka on 08.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines attributes identifying endpoint

public protocol EndpointIdentifiable: Identifiable {
    var identifiableComponents: [String] { get }
}

// MARK: - Default implementation for endpoint identifiable

public extension EndpointIdentifiable {
    var identifier: String {
        identifiableComponents.filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .joined(separator: "_")
    }
}

// MARK: - Default implementation for URLRequest

extension URLRequest: EndpointIdentifiable {
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
