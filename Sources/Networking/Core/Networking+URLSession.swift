//
//  Networking+URLSession.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Implementation of networking for URLSession
/// Extension of URLSession to provide request publisher running upon URL session
extension URLSession: Networking {    
    /// Creates request publisher using dataTaskPublisher and mapping error
    /// - Parameter request: URL request which is called
    /// - Returns: publisher streaming ``Response`` or throwing ``NetworkError``
    public func request(for request: URLRequest) async throws -> Response {
        try await URLSession.shared.data(for: request, delegate: nil)
    }
}
