//
//  AuthenticationTokenDataModel.swift
//
//
//  Created by Martin Vidovic on 03.02.2022.
//

import Foundation

// MARK: - Authentication token data model

/// A default model that implements ``AuthenticationTokenData``, it holds typical values required for OAuth authentication.
struct AuthenticationTokenDataModel: Codable, AuthenticationTokenData {
    let authenticationToken: String
    let refreshToken: String?
    let authenticationTokenExpirationDate: Date?
    let refreshTokenExpirationDate: Date?
}
