//
//  NetworkError.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines networking errors

/// Error thrown during ``Response`` processing or underlaying ``Networking`` error
public enum NetworkError: Error, LocalizedError {
    /// when received http status code in not accepted as valid
    case unacceptableStatusCode(
        statusCode: HTTPStatusCode,
        acceptedStatusCodes: Range<HTTPStatusCode>,
        response: Response
    )
    /// when response misses http status code
    case noStatusCode(response: Response)
    /// underlaying network layer error
    case underlying(error: Error)
    /// error with unknown cause
    case unknown

    public var errorDescription: String? {
        switch self {
        case let .unacceptableStatusCode(statusCode, range, _):
            return NSLocalizedString("Unaccepted status code \(statusCode), allowed range is \(range)", comment: "")
        case .noStatusCode:
            return NSLocalizedString("Response is missing status code", comment: "")
        case let .underlying(error):
            return NSLocalizedString("Network error \(error.localizedDescription)", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        }
    }
}
