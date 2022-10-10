//
//  HTTPStatusCode.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - HTTPStatusCode

/// Hide status code `Int` type under own type
public typealias HTTPStatusCode = Int

// MARK: - HTTP status code ranges

/// Ranges for most common http status codes
public extension HTTPStatusCode {
    /// HTTP status code between 200-300
    static var successCodes: Range<HTTPStatusCode> {
        200 ..< 300
    }

    /// HTTP status code between 300-400
    static var redirectCodes: Range<HTTPStatusCode> {
        300 ..< 400
    }

    /// HTTP status code between 200-400
    static var successAndRedirectCodes: Range<HTTPStatusCode> {
        200 ..< 400
    }
}
