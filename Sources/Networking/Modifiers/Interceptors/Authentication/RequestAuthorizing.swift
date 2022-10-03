//
//  RequestAuthorizing.swift
//
//
//  Created by Tomas Cejka on 13.09.2021.
//

import Foundation

// MARK: - RequestAuthorizing

/// A type that is able to authorize a URL request.
public protocol RequestAuthorizing {
    /// Authorizes a given `URLRequest`.
    /// - Parameters:
    ///   - request: The request to be authorized.
    /// - Returns: A `Result` with success containing authorized URL request or failure as a ``AuthenticationError``.
    func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError>
}
