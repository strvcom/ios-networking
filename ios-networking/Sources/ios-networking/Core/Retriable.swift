//
//  Retriable.swift
//  STRV_template
//
//  Created by Tomas Cejka on 02.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// Defines which objects should retry
public protocol Retriable {
    var shouldRetry: Bool { get }
}
