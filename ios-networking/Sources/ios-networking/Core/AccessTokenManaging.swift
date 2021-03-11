//
//  AccessTokenManaging.swift
//  STRV_template
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation


public protocol AccessTokenManaging {
    var accessToken: String? { get set }
    var expirationDate: Date? { get set }
    var refreshToken: String? { get set }
    var refreshExpirationDate: Date? { get set }

    var isExpired: Bool { get }
}
