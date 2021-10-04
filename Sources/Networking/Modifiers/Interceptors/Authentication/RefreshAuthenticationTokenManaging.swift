//
//  RefreshAuthenticationTokenManaging.swift
//  STRV_template
//
//  Created by Tomas Cejka on 01.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines responsibility for refreshing authentication token

public protocol RefreshAuthenticationTokenManaging {
    // refresh authentication token with refresh token, as an output is any data structure containing token management values
    func refreshAuthenticationToken(_ refreshToken: String) -> AnyPublisher<AuthenticationTokenData, AuthenticationError>
}
