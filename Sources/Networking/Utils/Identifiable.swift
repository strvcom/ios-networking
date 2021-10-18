//
//  Identifiable.swift
//  Networking
//
//  Created by Tomas Cejka on 01.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// Require identifier for object
public protocol Identifiable {
    var identifier: String { get }
}
