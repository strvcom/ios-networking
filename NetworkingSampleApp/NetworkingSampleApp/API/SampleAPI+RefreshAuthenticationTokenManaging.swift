//
//  SampleAPI+RefreshAuthenticationTokenManaging.swift
//  NetworkingSampleApp
//
//  Created by Tomas Cejka on 06.09.2021.
//

import Combine
import Foundation
import Networking

// MARK: SampleAPI as refresh authentication token manager

extension SampleAPI: RefreshAuthenticationTokenManaging {
    func refreshAuthenticationToken(_: String) -> AnyPublisher<AuthenticationTokenData, AuthenticationError> {
        // map response data which are just token to full sample authentication data
        authUserPublisher()
            .map { authResponse in
                var mutableAuthenticationResponse = authResponse
                mutableAuthenticationResponse.authenticationToken = "authenticationToken"
                mutableAuthenticationResponse.authenticationTokenExpirationDate = Date(timeIntervalSinceNow: 1000)
                mutableAuthenticationResponse.refreshToken = "refreshToken"
                mutableAuthenticationResponse.refreshTokenExpirationDate = Date(timeIntervalSinceNow: 100000)

                return mutableAuthenticationResponse
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Wrap request to use request method with proper signature, usually wrapped by service

private extension SampleAPI {
    func authUserPublisher() -> AnyPublisher<SampleUserAuthResponse, AuthenticationError> {
        apiManager
            .request(
                SampleUserRouter.loginUser(
                    SampleUserAuthRequest(
                        email: SampleAPIConstants.validEmail,
                        password: SampleAPIConstants.validPassword
                    )
                )
            )
            .mapError { _ in .unauthorized }
            .eraseToAnyPublisher()
    }
}
