//
//  RequestableError.swift
//  Networking
//
//  Created by Tomas Cejka on 11.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines errors for endpoints composing URL request

/// Errors which can be thrown when creating URL requests from ``Requestable``
public enum RequestableError: Error {
    /// Throwing when creation of `URLRequest` from `URLComponents` fails
    case invalidURLComponents
}
