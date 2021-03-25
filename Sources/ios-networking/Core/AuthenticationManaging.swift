//
//  AuthenticationManaging.swift
//  STRV_template
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Defines authentication managing

public protocol AuthenticationManaging {
    var isAuthenticated: Bool { get }
    
    func authenticate(_ requestPublisher: AnyPublisher<URLRequest, Error>) -> AnyPublisher<URLRequest, Error>
}
