//
//  Retriable.swift
//  STRV_template
//
//  Created by Tomas Cejka on 02.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines error is retriable

public protocol Retriable {
    var shouldRetry: Bool { get }
}
