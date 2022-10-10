//
//  Identifiable.swift
//  Networking
//
//  Created by Tomas Cejka on 01.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

/// A type that has a unique identifier.
public protocol Identifiable {
    var identifier: String { get }
}
