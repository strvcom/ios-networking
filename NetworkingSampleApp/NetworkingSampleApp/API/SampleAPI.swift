//
//  SampleAPI.swift
//  Networking
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

final class SampleAPI: AuthenticationProviding {
    func authenticate() {}
    
    // MARK: Private properties
    private lazy var cancellables = Set<AnyCancellable>()
    private lazy var reachability: Reachability? = try? Reachability()
    private(set) lazy var keychainAuthenticationManager: KeychainAuthenticationManager = {
        KeychainAuthenticationManager(authenticationProvider: self)
    }()
    
    // MARK: Lifecycle

    init() {}
}

// MARK: - Public methods

extension SampleAPI {
    func runSamples() {
        runReachabilitySample()
//        runDecodableSample()
//        runDecodableSample()
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
