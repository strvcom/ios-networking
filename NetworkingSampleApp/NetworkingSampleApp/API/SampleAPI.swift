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

// MARK: SampleAPI
// SampleAPI implements RefreshAuthenticationTokenManaging
// SampleAPI calls various sample request for authentication, retry or observe reachability

final class SampleAPI {
    // MARK: Constants for sample API calling regres.in
    enum SampleAPIConstants {
        static let validEmail = "eve.holt@reqres.in"
        static let validPassword = "cityslicka"
        static let sampleEmail = "email@email.me"
        static let sampleName = "Dummy"
        static let sampleJob = "Foo"
    }

    // MARK: Private properties
    private lazy var cancellables = Set<AnyCancellable>()
    private lazy var reachability: Reachability? = try? Reachability()
    private lazy var keychainAuthenticationTokenManager = KeychainAuthenticationTokenManager(refreshAuthenticationTokenManager: self)

    private(set) lazy var apiManager: APIManager = {
        var responseProcessors: [ResponseProcessing] = [
            StatusCodeProcessor(),
            SampleAPIErrorProcessor(),
            AuthorizationTokenInterceptor(
                authenticationProvider: keychainAuthenticationTokenManager
            ),
            LoggingInterceptor()
        ]

        #if DEBUG
            // stores the whole API call to a local file
            responseProcessors.append(EndpointRequestStorageProcessor())
        #endif

        return APIManager(
            authenticationManager: keychainAuthenticationTokenManager,
            requestAdapters: [
                AuthorizationTokenInterceptor(
                    authenticationProvider: keychainAuthenticationTokenManager
                ),
                LoggingInterceptor()
            ],
            responseProcessors: responseProcessors
        )
    }()

    // MARK: Lifecycle

    init() {
        // set default data for simulation of authentication, like after login
        let authenticationTokenData = SampleUserAuthResponse(
            authenticationToken: nil,
            refreshToken: "",
            authenticationTokenExpirationDate: nil,
            refreshTokenExpirationDate: Date(timeIntervalSinceNow: 1_000_000)
        )
        keychainAuthenticationTokenManager.store(authenticationTokenData)
    }
}

// MARK: - Public methods

extension SampleAPI {
    func runSamples() {
//        runReachabilitySample()
        runDecodableSample()
        runDecodableSample()
//        runPostBodySample()
//        runURLParametersSample()
//        runCustomErrorDecodingSample()
    }
}

// MARK: - Run reachability samples

private extension SampleAPI {
    func runReachabilitySample() {
        // subscribe reachability connection
        reachability?.connection
            .sink { completion in
                print(completion)
            } receiveValue: { value in
                print(value)
            }
            .store(in: &cancellables)

        // subscribe reachable state
        reachability?.isReachable
            .sink { completion in
                print(completion)
            } receiveValue: { value in
                print(value)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Run decodable sample

private extension SampleAPI {
    func runDecodableSample() {
        // success expected, decode data model
        // publisher to set right return type from request, usually defined by service
        let userPublisher: AnyPublisher<SampleUsersResponse, Error> = apiManager
            .request(
                SampleUserRouter.users(page: 2)
            )

        userPublisher
            .sink(
                receiveCompletion: { completion in
                    print(completion)
                },
                receiveValue: { value in
                    print(value)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Run custom error decoding sample

private extension SampleAPI {
    func runCustomErrorDecodingSample() {
        // fail expected, decode server error response to custom error
        apiManager
            .request(
                SampleUserRouter.registerUser(
                    SampleUserAuthRequest(
                        email: SampleAPIConstants.sampleEmail,
                        password: nil
                    )
                )
            )
            .sink(
                receiveCompletion: { completion in
                    print(completion)
                },
                receiveValue: { value in
                    print(value)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Run sample request with url parameters

private extension SampleAPI {
    func runURLParametersSample() {
        // success expected, url params testing
        apiManager
            .request(
                SampleUserRouter.users(page: 2)
            )
            .sink(
                receiveCompletion: { completion in
                    print(completion)
                },
                receiveValue: { value in
                    print(value)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Run sample request post body

private extension SampleAPI {
    func runPostBodySample() {
        // success expected, post body encoding test
        apiManager.request(
            SampleUserRouter.createUser(
                SampleUserRequest(
                    name: SampleAPIConstants.sampleName,
                    job: SampleAPIConstants.sampleJob
                )
            )
        )
        .sink(
            receiveCompletion: { completion in
                print(completion)
            },
            receiveValue: { value in
                print(value)
            }
        )
        .store(in: &cancellables)
    }
}
