//
//  HTTPStatusCode.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

/// A status code included in an HTTP response.
public typealias HTTPStatusCode = Int

/// Ranges for the most common HTTP status codes.
public extension HTTPStatusCode {
    /// HTTP status code between 200-300.
    static var successCodes: Range<HTTPStatusCode> {
        200 ..< 300
    }

    /// HTTP status code between 300-400.
    static var redirectCodes: Range<HTTPStatusCode> {
        300 ..< 400
    }

    /// HTTP status code between 200-400.
    static var successAndRedirectCodes: Range<HTTPStatusCode> {
        200 ..< 400
    }
    
    static var nonRetriableCodes: ClosedRange<HTTPStatusCode> {
        400...499
    }
}
