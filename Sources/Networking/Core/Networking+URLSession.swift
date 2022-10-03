//
//  Networking+URLSession.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Implementation of networking for URLSession

extension URLSession: Networking {
    /// Creates a network request for a `URLRequest`.
    /// - Parameter for: URL request which is called.
    /// - Returns: response.
    /// - Throws: ``NetworkError``.
    public func request(for request: URLRequest) async throws -> Response {
        try await URLSession.shared.data(for: request, delegate: nil)
    }
}
