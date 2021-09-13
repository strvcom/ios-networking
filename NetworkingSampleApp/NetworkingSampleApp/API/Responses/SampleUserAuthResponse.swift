//
//  SampleUserAuthResponse.swift
//  networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation
import Networking

struct SampleUserAuthResponse: Decodable, AuthenticationTokenData {
    let authenticationToken: String?
    let refreshToken: String?
    let authenticationTokenExpirationDate: Date?
    let refreshTokenExpirationDate: Date?
}
