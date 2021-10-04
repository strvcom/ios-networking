//
//  RefreshAuthenticationCredentialsManaging.swift
//
//
//  Created by Tomas Cejka on 04.10.2021.
//

import Combine
import Foundation

// MARK: - Defines responsibility for refreshing authentication token

public protocol RefreshAuthenticationCredentialsManaging {
    // refresh authentication token with credentials, as an output is authentication token
    func refreshAuthenticationToken(login: String, password: String) -> AnyPublisher<String, AuthenticationError>
}
