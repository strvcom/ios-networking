//
//  SampleAPI.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation
import Networking

// Custom API object
// For simplicity it manages also auth token with refresh logic
final class SampleAPI: AuthenticationTokenManaging {
    var refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging { self }

    var isAuthenticated: Bool {
        !isExpired && authenticationToken != nil
    }

    var authenticationToken: String?
    var expirationDate: Date?
    var refreshToken: String?
    var refreshExpirationDate: Date?
    var isExpired: Bool {
        guard let expirationDate = expirationDate else {
            return true
        }
        return expirationDate <= Date()
    }

    var cancellables = Set<AnyCancellable>()

    lazy var reachability: Reachability? = try? Reachability()

    lazy var apiManager: APIManager = {
        var responseProcessors: [ResponseProcessing] = [
            StatusCodeProcessor(),
            SampleAPIErrorProcessor(),
            AuthorizationTokenInterceptor(authenticationManager: self),
            LoggingInterceptor()
        ]

        #if DEBUG
            // allows store whole api call to local file
            responseProcessors.append(EndpointRequestStorageProcessor())
        #endif

        return APIManager(
            requestAdapters: [
                AuthorizationTokenInterceptor(authenticationManager: self),
                LoggingInterceptor()
            ],
            responseProcessors: responseProcessors
        )
    }()

    func run() {
        // test reachability
        reachability?.connection
            .sink { completion in
                print(completion)
            } receiveValue: { value in
                print(value)
            }
            .store(in: &cancellables)

        // test reachability
        reachability?.isReachable
            .sink { completion in
                print(completion)
            } receiveValue: { value in
                print(value)
            }
            .store(in: &cancellables)

        // success expected, decode data model
        let userPublisher: AnyPublisher<SampleUsersResponse, Error> = apiManager.request(SampleUserRouter.users)

        userPublisher
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { value in
                    print(value)
                }
            ).store(in: &cancellables)

        // success expected, url params testing
        apiManager.request(SampleUserRouter.users)
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in }
            ).store(in: &cancellables)

        // success expected
        apiManager.request(SampleUserRouter.user(2))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)

        // success expected, post body encoding test
        apiManager.request(SampleUserRouter.createUser(SampleUserRequest(name: "CJ", job: "Developer")))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)

        // custom error processing
        apiManager.request(SampleUserRouter.registerUser(SampleUserAuthRequest(email: "test@test.test", password: nil)))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)
    }
}

extension SampleAPI: RefreshAuthenticationTokenManaging {
    func refreshAuthenticationToken() -> AnyPublisher<String, Error> {
        let accessTokenPublisher: AnyPublisher<SampleUserAuthResponse, Error> = apiManager.request(SampleUserRouter.loginUser(SampleUserAuthRequest(email: "eve.holt@reqres.in", password: "cityslicka")))

        return accessTokenPublisher
            .map { response in
                self.authenticationToken = response.token
                return response.token
            }
            .eraseToAnyPublisher()
    }
}
