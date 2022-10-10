//
//  AuthenticationTokenDataModel.swift
//
//
//  Created by Martin Vidovic on 03.02.2022.
//

import Foundation

// MARK: - Authentication token data model

/// Model holding typical values required for refresh authentication token authentication system
struct AuthenticationTokenDataModel: Codable, AuthenticationTokenData {
    let authenticationToken: String
    let refreshToken: String?
    let authenticationTokenExpirationDate: Date?
    let refreshTokenExpirationDate: Date?
}
