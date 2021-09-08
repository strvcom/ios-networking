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
    func refreshAuthenticationToken() -> AnyPublisher<String, Error> {
        let accessTokenPublisher: AnyPublisher<SampleUserAuthResponse, Error> = apiManager
            .request(
                SampleUserRouter.loginUser(
                    SampleUserAuthRequest(
                        email: SampleAPIConstants.validEmail,
                        password: SampleAPIConstants.validPassword
                    )
                )
            )

        return accessTokenPublisher
            .handleEvents(receiveOutput: { [weak self] response in
                self?.authenticationToken = response.token
                self?.expirationDate = Date(timeIntervalSinceNow: 3600)
            })
            .map(\.token)
            .eraseToAnyPublisher()
    }
}
