//
//  RefreshAuthenticationTokenManaging.swift
//  STRV_template
//
//  Created by Tomas Cejka on 01.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// MARK: - Defines responsibility for refreshing authentication token

public protocol RefreshAuthenticationTokenManaging {
    func refreshAuthenticationToken() -> AnyPublisher<String, Error>
}
