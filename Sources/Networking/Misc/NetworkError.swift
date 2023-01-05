//
//  NetworkError.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines networking errors

/// An error that occurs during ``Response`` processing or an underlaying ``Networking`` error.
public enum NetworkError: Error, LocalizedError {
    /// An indication that the received HTTP status code in not accepted as valid.
    case unacceptableStatusCode(
        statusCode: HTTPStatusCode,
        acceptedStatusCodes: Range<HTTPStatusCode>,
        response: Response
    )
    /// An indication that the response misses an HTTP status code.
    case noStatusCode(response: Response)
    /// An indication of an underlaying network layer error.
    case underlying(error: Error)
    /// An indication of an invalid response header.
    case headerIsInvalid
    /// An indication of an unknown cause.
    case unknown

    public var errorDescription: String? {
        switch self {
        case let .unacceptableStatusCode(statusCode, range, _):
            return NSLocalizedString("Unaccepted status code \(statusCode), allowed range is \(range)", comment: "")
        case .noStatusCode:
            return NSLocalizedString("Response is missing status code", comment: "")
        case let .underlying(error):
            return NSLocalizedString("Network error \(error.localizedDescription)", comment: "")
        case .headerIsInvalid:
            return NSLocalizedString("Header is not valid", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        }
    }
}
