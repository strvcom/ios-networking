//
//  RefreshTokenRequest.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 12.12.2022.
//

import Foundation

/// Model for sample API refresh token request
struct SampleRefreshTokenRequest: Encodable {
    let refreshToken: String
}
