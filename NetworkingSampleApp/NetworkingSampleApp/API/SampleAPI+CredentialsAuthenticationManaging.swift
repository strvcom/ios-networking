//
//  SampleAPI+CredentialsAuthenticationManaging.swift
//  NetworkingSampleApp
//
//  Created by Tomas Cejka on 05.10.2021.
//

import Combine
import Foundation
import Networking

// MARK: SampleAPI as authentication with credentials manager

// extension SampleAPI: RenewAuthenticationByCredentialsManaging {
//    func refreshAuthenticationToken(login: String, password: String) -> AnyPublisher<String, AuthenticationError> {
//        apiManager
//            .request(
//                SampleUserRouter.loginUser(
//                    SampleUserAuthRequest(
//                        email: login,
//                        password: password
//                    )
//                )
//            )
//            .mapError { _ in .unauthorized }
//            .eraseToAnyPublisher()
//    }
// }
