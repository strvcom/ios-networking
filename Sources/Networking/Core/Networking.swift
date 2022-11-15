//
//  Networking.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines networking layer which allows to make a request

/// Definition of network layer which makes request and receive data
public protocol Networking {
    /// Creates publisher for request to stream responses if API call works
    /// - Parameter for: request for URLSession
    /// - Returns: received data
    func request(for: URLRequest) async throws -> Response
}
