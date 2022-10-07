//
//  AuthenticationProviding.swift
//
//
//  Created by Tomas Cejka on 16.12.2021.
//

import Foundation

/// A type that is able to authenticate with an API service.
public protocol AuthenticationProviding {
    /// Authenticate with an API service.
    func authenticate() -> Void
}
