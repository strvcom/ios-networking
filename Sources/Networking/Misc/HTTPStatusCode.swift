//
//  HTTPStatusCode.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

public typealias HTTPStatusCode = Int

// MARK: - HTTP status code ranges

extension HTTPStatusCode {
    static var successCodes: Range<HTTPStatusCode> {
        200..<300
    }

    static var redirectCodes: Range<HTTPStatusCode> {
        300..<400
    }

    static var successAndRedirectCodes: Range<HTTPStatusCode> {
        200..<400
    }
}
