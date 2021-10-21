//
//  AuthenticationError.swift
//
//  Created by Tomas Cejka on 22.03.2021.
//

import Foundation

// MARK: - Defines base authentication errors

/// Authentication error indicates failure during whole request flow
public enum AuthenticationError: Error, LocalizedError, Retrying {
    case unauthorized
    case missingAuthenticationToken
    case expiredAuthenticationToken
    case missingRefreshToken
    case missingCredentials
    case expiredRefreshToken
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
        case .missingCredentials:
            return NSLocalizedString("Missing credentials", comment: "")
        case .expiredRefreshToken:
            return NSLocalizedString("Expired refresh token", comment: "")
        case .custom(let error):
            return NSLocalizedString("Custom authentication error \(error.localizedDescription)", comment: "")
        }
    }

    public var shouldRetry: Bool {
        true
    }
}
