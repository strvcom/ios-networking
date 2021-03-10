//
//  ExampleAPI.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import Combine
import ios_networking

class ExampleAPI: AccessTokenManaging {
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
    
    //lazy var reachability: Reachability? = Reachability()
    
    lazy var apiManager: STRVAPIManager = {
        var responseProcessors: [ResponseProcessing] = [
            StatusCodeProcessor(),
            ExampleAPIErrorProcessing(),
            AuthorizationTokenInterceptor(accessTokenManager: self, refreshTokenPublisher: self),
            LoggingInterceptor()
        ]
        
        #if DEBUG
        responseProcessors.append(APIStorageProcessor())
        #endif
        
        return STRVAPIManager(
            requestAdapters: [
                AuthorizationTokenInterceptor(accessTokenManager: self, refreshTokenPublisher: self),
                LoggingInterceptor()
            ],
            responseProcessors: responseProcessors
        )
    }()
    
    func run() {
        
        // test reachability
        // TODO:
//        reachability?.connection
//            .sink { completion in
//                print(completion)
//            } receiveValue: { value in
//                print(value)
//            }
//            .store(in: &cancellables)
        
        // test reachability
        // TODO
//        reachability?.isReachable
//            .sink { completion in
//                print(completion)
//            } receiveValue: { value in
//                print(value)
//            }
//            .store(in: &cancellables)
        
        // success expected, url params testing
        apiManager.request(ExampleUserRouter.users)
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)
        
        // success expected
        apiManager.request(ExampleUserRouter.user(2))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)
        
        // success expected, post body encoding test
        apiManager.request(ExampleUserRouter.createUser(ExampleUserRequest(name: "CJ", job: "Developer")))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)
        
        // custom error processing
        apiManager.request(ExampleUserRouter.registerUser(ExampleUserAuthRequest(email: "test@test.test", password: nil)))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)
        
        // error expected -> auth processing -> retry
        apiManager.request(ExampleUserRouter.user(23))
            .sink(
                receiveCompletion: { _ in
                }, receiveValue: { _ in
                }
            ).store(in: &cancellables)
        
    }
}

extension ExampleAPI: RefreshTokenPublishing {
    func refreshAuthenticationToken() -> AnyPublisher<String, Error> {
        let accessTokenPublisher: AnyPublisher<ExampleUserAuthResponse, Error> = apiManager.request(ExampleUserRouter.loginUser(ExampleUserAuthRequest(email: "eve.holt@reqres.in", password: "cityslicka")))
        
        return accessTokenPublisher
            .map { response in
                self.accessToken = response.token
                return response.token
            }
            .eraseToAnyPublisher()
    }
}
