//
//  AuthorizationToken.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public struct AuthorizationToken: AuthorizationData {
    public let accessToken: String
    public let refreshToken: String
    public let expiryDate: Date?
    
    public var header: String {
        "Bearer \(accessToken)"
    }
}
