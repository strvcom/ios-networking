//
//  AuthenticationProviding.swift
//
//
//  Created by Tomas Cejka on 16.12.2021.
//

import Combine
import Foundation

/// Protocol defines object which can return authentication publisher
public protocol AuthenticationProviding {
    /// Authenticate to API service
    /// - Returns: Publisher streaming events that authentication is done
    func authenticate() -> AnyPublisher<Void, AuthenticationError>
}
