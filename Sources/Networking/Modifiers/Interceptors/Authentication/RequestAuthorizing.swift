//
//  RequestAuthorizing.swift
//
//
//  Created by Tomas Cejka on 13.09.2021.
//

import Foundation

// MARK: - RequestAuthorizing

/// Defines mechanism to authorize URL request
public protocol RequestAuthorizing {
    /// Depending on authentication type object conforming this protocol is responsible for proper authorization of requests
    /// - Returns: Result with success containing authorized URL request or failure as a ``AuthenticationError``
    func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError>
}
