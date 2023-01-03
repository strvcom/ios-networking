//
//  SampleUserAuthResponse.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation
import Networking

/// Data structure of sample API authentication response
struct SampleUserAuthResponse {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Date
}

// MARK: Decodable
extension SampleUserAuthResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, expiresIn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
        
        let expiresInEpoch = try container.decode(Double.self, forKey: .expiresIn)
        expiresIn = Date(timeIntervalSince1970: expiresInEpoch)
    }
}

// MARK: Mapping to AuthorizationData
extension SampleUserAuthResponse {
    var authData: AuthorizationData {
        AuthorizationData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}
