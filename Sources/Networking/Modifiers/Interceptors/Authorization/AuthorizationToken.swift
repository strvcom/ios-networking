//
//  AuthorizationToken.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public struct AuthorizationData {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Date?
    /// Offset indicates how soon before expiration should access token be refreshed to avoid group requests failures.
    public let offset: TimeInterval
    
    public init(accessToken: String, refreshToken: String, expiresIn: Date?, offset: TimeInterval = 60) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.offset = offset
    }
}

// MARK: Computed propeties
extension AuthorizationData {
    public var header: String {
        "Bearer \(accessToken)"
    }
    
    public var isExpired: Bool {
        guard let expiresIn else {
            /// If there is no information about expiration, always assume it is not expired.
            return false
        }
        /// Adding a safe offset so the access token can be pre-emptively refreshed.
        return expiresIn < Date().addingTimeInterval(offset)
    }
}
