//
//  SampleUserAuthResponse.swift
//  networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation
import Networking

struct SampleUserAuthResponse: Decodable, RefreshTokenData {
    var authenticationToken: String?
    var refreshToken: String?
    var authenticationTokenExpirationDate: Date?
    var refreshTokenExpirationDate: Date?
}
