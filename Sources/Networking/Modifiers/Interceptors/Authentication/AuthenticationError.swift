//
//  AuthenticationError.swift
//
//  Created by Tomas Cejka on 22.03.2021.
//

import Foundation

// MARK: - Defines base authentication errors

// TODO:

/// An error that indicates an authentication failure and occurs during the whole request flow.
public enum AuthenticationError: Error, LocalizedError {
    /// An indication that the API request failed to authorise.
    case unauthorized
    /// An indication that a required authentication token for HTTP header is missing.
    case missingAuthenticationToken
    /// An indication that the required authentication token for HTTP header is expired.
    case expiredAuthenticationToken
    /// An indication that a required refresh token for HTTP header is missing.
    case missingRefreshToken
    /// An indication that the required refresh token for HTTP header is expired.
    case expiredRefreshToken
    /// An indication of an underlaying custom error. For a case where Networking is working with custom authentication mechanism.
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
