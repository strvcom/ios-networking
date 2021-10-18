//
//  Retrying.swift
//  Networking
//
//  Created by Tomas Cejka on 02.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines error is retrying

public protocol Retrying {
    var shouldRetry: Bool { get }
}
