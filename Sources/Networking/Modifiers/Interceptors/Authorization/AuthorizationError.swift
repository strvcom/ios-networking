//
//  File.swift
//  
//
//  Created by Dominika Gajdová on 02.01.2023.
//

import Foundation

// MARK: - Defines base authorization errors
public enum AuthorizationError: Error, LocalizedError {
    case unauthorized
    case missingAccessToken
    case expiredAccessToken
    case expiredRefreshToken

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("Unauthorized access", comment: "")
        case .missingAccessToken:
            return NSLocalizedString("Missing access token", comment: "")
        case .expiredAccessToken:
            return NSLocalizedString("Access token expired", comment: "")
        case .expiredRefreshToken:
            return NSLocalizedString("Refresh token expired", comment: "")
        }
    }
}
