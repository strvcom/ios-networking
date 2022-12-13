//
//  SampleUserAuthResponse.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation

/// Data structure of sample API authentication response
struct SampleUserAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Date
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }

//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.accessToken = try container.decode(String.self, forKey: .accessToken)
//        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
//        self.tokenType = try container.decode(String.self, forKey: .tokenType)
//        self.expiresIn = try container.decode(Date.self, forKey: .expiresIn)
//    }
}
