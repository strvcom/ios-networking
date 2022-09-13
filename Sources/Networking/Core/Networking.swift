//
//  Networking.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines networking layer which allows to make a request

/// A definition of a Network layer which makes a request and receives data.
///
/// By default Networking library uses `URLSession` to make API calls.
public protocol Networking {
    /// Creates a network request for a `URLRequest`.
    /// - Parameter for: URL request which is called.
    /// - Returns: ``Response``.
    /// - Throws: ``NetworkError``.
    func request(for: URLRequest) async throws -> Response
}
