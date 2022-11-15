//
//  Networking+URLSession.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Implementation of networking for URLSession

/// Extension of URLSession providing networking layer
extension URLSession: Networking {
    /// Creates request  using data task
    /// - Parameter request: URL request which is called
    /// - Returns: received data
    /// - Throws: ``NetworkError``
    public func request(for request: URLRequest) async throws -> Response {
        try await URLSession.shared.data(for: request, delegate: nil)
    }
}
