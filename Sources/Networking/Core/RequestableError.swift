//
//  RequestableError.swift
//  Networking
//
//  Created by Tomas Cejka on 11.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

/// An Error that occurs during the creation of `URLRequest` from ``Requestable``.
public enum RequestableError: Error {
    /// An indication that the properties in ``Requestable`` cannot form valid `URLComponents`.
    case invalidURLComponents
}
