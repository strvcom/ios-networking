//
//  AuthenticationTokenData.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Foundation

public protocol AuthenticationTokenData {
    var authenticationToken: String? { get }
    var authenticationTokenExpirationDate: Date? { get }
    var refreshToken: String? { get }
    var refreshTokenExpirationDate: Date? { get }
}
