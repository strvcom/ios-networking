//
//  SampleAPI.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import Combine
import ios_networking

// Custom API object
// For simplicity it manages also auth token with refresh logic
final class SampleAPI: AccessTokenManaging {
    var accessToken: String?
    var expirationDate: Date?
    var refreshToken: String?
    var refreshExpirationDate: Date?
    var isExpired: Bool {
        // swiftlint:disable:next force_unwrapping
        !((expirationDate != nil && (expirationDate)! > Date())
            || expirationDate == nil)
    }
    
    var cancellables = Set<AnyCancellable>()
    
    lazy var reachability: Reachability? = Reachability()
    
    lazy var apiManager: APIManager = {
        var responseProcessors: [ResponseProcessing] = [
            StatusCodeProcessor(),
            SampleAPIErrorProcessor(),
            AuthorizationTokenInterceptor(accessTokenManager: self, refreshTokenPublisher: self),
            LoggingInterceptor()
        ]
        
        #if DEBUG
        // allows store whole api call to local file
        responseProcessors.append(EndpointRequestStorageProcessor())
        #endif
        
        return APIManager(
            requestAdapters: [
                AuthorizationTokenInterceptor(accessTokenManager: self, refreshTokenPublisher: self),
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
        
        // success expected, url params testing
        apiManager.request(SampleUserRouter.users)
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
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
        
        // error expected -> auth processing -> retry
        apiManager.request(SampleUserRouter.user(23))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)
        
    }
}

extension SampleAPI: RefreshTokenPublishing {
    func refreshAuthenticationToken() -> AnyPublisher<String, Error> {
        let accessTokenPublisher: AnyPublisher<SampleUserAuthResponse, Error> = apiManager.request(SampleUserRouter.loginUser(SampleUserAuthRequest(email: "eve.holt@reqres.in", password: "cityslicka")))
        
        return accessTokenPublisher
            .map { response in
                self.accessToken = response.token
                return response.token
            }
            .eraseToAnyPublisher()
    }
}
