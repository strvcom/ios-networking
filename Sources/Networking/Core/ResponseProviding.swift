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

    /// Invalidates and response provider to gracefully clear out all its tasks.
    func invalidate() async
}

extension URLSession: ResponseProviding {
    /// Creates a ``Response`` for a given `URLRequest` by firing a network request.
    public func response(for request: URLRequest) async throws -> Response {
        try await data(for: request)
    }

    /// Invalidates and response provider to gracefully clear out all its tasks.
    /// Warning: URLSession can no longer be used after it's been invalidated and any usage
    /// will lead to a crash.
    public func invalidate() async {
        await allTasks.forEach { $0.cancel() }
        invalidateAndCancel()
    }
}
