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

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("Unauthorized access", comment: "")
        case .missingAuthenticationToken:
            return NSLocalizedString("Missing authentication token", comment: "")
        case .expiredAuthenticationToken:
            return NSLocalizedString("Authentication token expired", comment: "")
        }
    }

    public var shouldRetry: Bool {
        true
    }
}
