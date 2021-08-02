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
    // Constants for sample API calling regres.in
    enum SampleAPIConstants {
        static let validEmail = "eve.holt@reqres.in"
        static let validPassword = "cityslicka"
        static let sampleEmail = "email@email.me"
        static let sampleName = "Dummy"
        static let sampleJob = "Foo"
    }

    var refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging { self }

    var isAuthenticated: Bool {
        authenticationToken != nil && !isExpired
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
            // stores the whole API call to a local file
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

    func sampleRun() {
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
        let userPublisher: AnyPublisher<SampleUsersResponse, Error> = apiManager.request(
            SampleUserRouter.users(page: 2)
        )

        userPublisher
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { value in
                    print(value)
                }
            )
            .store(in: &cancellables)

        // success expected, url params testing
        apiManager.request(SampleUserRouter.users(page: 2))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // success expected
        apiManager.request(SampleUserRouter.user(userId: 2))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            )
            .store(in: &cancellables)

        // success expected, post body encoding test
        apiManager.request(
            SampleUserRouter.createUser(
                SampleUserRequest(name: SampleAPIConstants.sampleName, job: SampleAPIConstants.sampleJob)
            ))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            )
            .store(in: &cancellables)

        // custom error processing
        apiManager.request(
            SampleUserRouter.registerUser(
                SampleUserAuthRequest(email: SampleAPIConstants.sampleEmail, password: nil)
            ))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            )
            .store(in: &cancellables)
    }
}

extension SampleAPI: RefreshAuthenticationTokenManaging {
    func refreshAuthenticationToken() -> AnyPublisher<String, Error> {
        let accessTokenPublisher: AnyPublisher<SampleUserAuthResponse, Error> = apiManager.request(
            SampleUserRouter.loginUser(
                SampleUserAuthRequest(
                    email: SampleAPIConstants.validEmail,
                    password: SampleAPIConstants.validPassword
                )
            )
        )

        return accessTokenPublisher
            .map { response in
                self.authenticationToken = response.token
                return response.token
            }
            .eraseToAnyPublisher()
    }
}
