//
//  Networking.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines networking layer which allows to make a request

/// Definition of network layer which makes request and receive data
///
/// By default Networking library uses `URLSession` to make API calls,
public protocol Networking {
    /// Creates publisher for request to stream responses if API call works
    /// - Returns: Publisher streaming ``Response`` value if networking succeed or ``NetworkError`` if communication failed
    func request(for: URLRequest) async throws -> Response
}
