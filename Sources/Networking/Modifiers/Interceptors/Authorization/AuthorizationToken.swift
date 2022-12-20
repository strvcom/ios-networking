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
    public let expiryDate: Date?
    
    public var header: String {
        "Bearer \(accessToken)"
    }
    
    public var isExpired: Bool {
        true
    }
}
