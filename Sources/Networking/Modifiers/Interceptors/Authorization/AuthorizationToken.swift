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
    
    public init(accessToken: String, refreshToken: String, expiresIn: Date?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
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
        return expiresIn < Date()
    }
}
