//
//  ExampleApiLayerManager.swift
//
//
//  Created by Martin Vidovic on 10.02.2022.
//

import Combine
import Foundation
import Networking

final class ExampleApiLayerManager {
    private(set) lazy var keychainAuthenticationManager: KeychainAuthenticationManager = {
        KeychainAuthenticationManager(authenticationProvider: self)
    }()

    private(set) lazy var apiManager: APIManager = {
        return APIManager(
            network: URLSession(configuration: .default),
            authenticationManager: keychainAuthenticationManager,
            requestAdapters: <#T##[RequestAdapting]#>,
            responseProcessors: <#T##[ResponseProcessing]#>
        )
    }()
}

extension ExampleApiLayerManager: AuthenticationProviding {
    func authenticate() -> AnyPublisher<Void, AuthenticationError> {
        /*
         - refreshing token is up to application -> it can be done via
            email + password or refreshToken, or using another way
         - application should have endpoint for refreshing authorization token.
         - in this example it is in UserRouter, which handles all logic for all endpoints connected to user
         */
        apiManager
            .request(UserRouter.loginUser(myRefreshToken))
            .mapError { _ in .unauthorized }
            .eraseToAnyPublisher()
    }
}
