//
//  RefreshTokenPublishing.swift
//  STRV_template
//
//  Created by Tomas Cejka on 01.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import Combine

// Defines responsibility for refresh token
public protocol RefreshTokenPublishing {
    func refreshAuthenticationToken() -> AnyPublisher<String, Error>
}
