//
//  SampleAppAuthenticationTokenData.swift
//  NetworkingSampleApp
//
//  Created by Tomas Cejka on 03.02.2022.
//

import Foundation
import Networking

struct SampleAppAuthenticationTokenData: AuthenticationTokenData {
    let authenticationToken: String
    let authenticationTokenExpirationDate: Date?
    let refreshToken: String?
    let refreshTokenExpirationDate: Date?
}
