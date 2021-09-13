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
        authUserPublisher()
            .map { $0 as AuthenticationTokenData }
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
