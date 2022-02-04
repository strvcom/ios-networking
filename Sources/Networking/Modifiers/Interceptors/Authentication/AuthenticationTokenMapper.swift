//
//  File.swift
//  
//
//  Created by Martin Vidovic on 04.02.2022.
//

import Foundation

protocol AuthenticationTokenMapping {
    func createModel(_ object: AuthenticationTokenData) -> AuthenticationTokenDataModel
}

struct AuthenticationTokenMapper: AuthenticationTokenMapping {
    func createModel(_ object: AuthenticationTokenData) -> AuthenticationTokenDataModel {
        AuthenticationTokenDataModel(
            authenticationToken: object.authenticationToken,
            refreshToken: object.refreshToken,
            authenticationTokenExpirationDate: object.authenticationTokenExpirationDate,
            refreshTokenExpirationDate: object.refreshTokenExpirationDate
        )
    }
}
