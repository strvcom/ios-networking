//
//  Identifiable.swift
//  Networking
//
//  Created by Tomas Cejka on 01.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

/// Object needs to be identified by its identifier
public protocol Identifiable {
    var identifier: String { get }
}
