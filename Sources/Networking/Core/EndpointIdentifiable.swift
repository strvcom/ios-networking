//
//  EndpointIdentifiable.swift
//  Networking
//
//  Created by Tomas Cejka on 08.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines attributes identifying endpoint

/// A type that has a unique identifier made up of an array of components.
///
/// The main purpose for this protocol is to be able to compare ``Requestable`` and `URLRequest`.
/// typically based on their URL path, query items and HTTP method.
/// This functionality is necessary to load correct sample data from file system.
public protocol EndpointIdentifiable: Identifiable {
    /// All components which are used for unique identifier, typically URL path, query items and HTTP method.
    var identifiableComponents: [String] { get }
}

// MARK: - Default implementation for endpoint identifiable

public extension Identifiable where Self: EndpointIdentifiable {
    /// By default endpointIdentifiable creates its identifier from `identifiableComponents` which are sorted, lowercased and joined by '\_' to avoid any issues matching identifiers.
    var identifier: String {
        identifiableComponents.filter { !$0.isEmpty }
            .map {
                $0.lowercased()
            }
            .joined(separator: "_")
    }
}

// MARK: - Default implementation for URLRequest

extension URLRequest: EndpointIdentifiable {
    /// Identifiable components from `URLRequest`.
    public var identifiableComponents: [String] {
        identifiableComponents(from: url, httpMethod: httpMethod)
    }
}

// MARK: - Default implementation identifying endpoint

public extension Requestable {
    /// Identifiable components from ``Requestable``.
    var identifiableComponents: [String] {
        identifiableComponents(from: try? urlComponents().url, httpMethod: method.rawValue)
    }
}

// MARK: - Helper function for identifiable components
private extension EndpointIdentifiable {
    /// Creates an array of identifiable components from URL path, query items and HTTP method.
    /// - Parameters:
    ///   - url: the full URL of a request.
    ///   - httpMethod: request HTTP method.
    /// - Returns: array of identifiable components.
    func identifiableComponents(from url: URL?, httpMethod: String?) -> [String] {
        guard
            let url = url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return []
        }
        
        var components: [String] = []
        
        // add path parts
        let pathComponents = urlComponents.path
            .split(separator: "/")
        // filter is needed in case the last path component is empty
            .filter { !$0.isEmpty }
            .map { String($0) }
        
        components.append(contentsOf: pathComponents)

        // the items need to be sorted because the final identifier should be the same no matter the order of query items in the URL
        let sortedQueryItems = urlComponents.queryItems?.sorted(by: { $0.name < $1.name })
        
        // add query items
        if let queryItems = sortedQueryItems {
            let mappedQueryItems = queryItems.flatMap { [$0.name, $0.value ?? ""] }
            components.append(contentsOf: mappedQueryItems)
        }

        // add method
        components.append(httpMethod ?? "")

        return components
    }
}

