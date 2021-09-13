//
//  AuthenticationError.swift
//
//  Created by Tomas Cejka on 22.03.2021.
//

import Foundation

// MARK: - Defines base authentication errors

public enum AuthenticationError: Error, LocalizedError, Retrying {
    case unauthorized
    case missingAuthenticationToken
    case expiredAuthenticationToken
    case missingRefreshToken
    case expiredRefreshToken

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
        }
    }

    public var shouldRetry: Bool {
        true
    }
}
