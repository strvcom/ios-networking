//
//  AuthenticationError.swift
//
//  Created by Tomas Cejka on 22.03.2021.
//

import Foundation

// MARK: - Defines base authentication errors

// TODO:

/// Authentication error indicates failure during whole request flow
public enum AuthenticationError: Error, LocalizedError {
    /// API calls failed as unauthorized
    case unauthorized
    /// Authentication manager haven't found authentication token for HTTP header
    case missingAuthenticationToken
    /// Authentication manager found authentication token expired
    case expiredAuthenticationToken
    /// Authentication manager haven't found refresh token
    case missingRefreshToken
    /// Authentication manager found refresh token expired
    case expiredRefreshToken
    /// For case Networking is working with custom authentication mechanism
    case custom(error: Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("Unauthorized access", comment: "")
        case .missingAuthenticationToken:
            return NSLocalizedString("Missing authentication token", comment: "")
        case .expiredAuthenticationToken:
            return NSLocalizedString("Authentication token expired", comment: "")
        case .missingRefreshToken:
            return NSLocalizedString("Missing refresh token", comment: "")
        case .expiredRefreshToken:
            return NSLocalizedString("Expired refresh token", comment: "")
        case let .custom(error):
            return NSLocalizedString("Custom authentication error \(error.localizedDescription)", comment: "")
        }
    }
}
