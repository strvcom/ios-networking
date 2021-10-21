//
//  Networking+URLSession.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Implementation of networking for URLSession
/// Extension of URLSession to provide request publisher running upon URL session
extension URLSession: Networking {
    /// Creates request publisher using dataTaskPublisher and mapping error
    /// - Parameter request: URL request which is called
    /// - Returns: publisher streaming ``Response`` or throwing ``NetworkError``
    public func requestPublisher(for request: URLRequest) -> AnyPublisher<Response, NetworkError> {
        dataTaskPublisher(for: request)
            .mapError(mapToNetworkError(_:))
            .eraseToAnyPublisher()
    }
}

// MARK: - Map URLError to NetworkError

private extension URLSession {
    func mapToNetworkError(_ error: URLError) -> NetworkError {
        .underlying(error: error)
    }
}
