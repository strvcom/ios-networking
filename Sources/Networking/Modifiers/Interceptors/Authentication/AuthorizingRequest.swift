//
//  AuthorizingRequest.swift
//
//
//  Created by Tomas Cejka on 13.09.2021.
//

import Foundation

// MARK: - AuthorizingRequest

/// Defines mechanism to authorize URL request
public protocol AuthorizingRequest {
    /// Depending on
    /// - Returns: Result with success containing authorized URL request or failure as a AuthenticationError
    func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError>
}
