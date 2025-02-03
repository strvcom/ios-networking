//
//  ResponseProviding.swift
//
//
//  Created by Matej Molnár on 04.01.2023.
//

import Foundation

/// A type is able to provide a ``Response`` for a given `URLRequest`.
///
/// By default the Networking library uses `URLSession` to make API calls.
public protocol ResponseProviding {
    /// Creates a ``Response`` for a given `URLRequest`.
    func response(for request: URLRequest) async throws -> Response
}

extension URLSession: ResponseProviding {
    /// Creates a ``Response`` for a given `URLRequest` by firing a network request.
    public func response(for request: URLRequest) async throws -> Response {
        try await data(for: request)
    }
}
