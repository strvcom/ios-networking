//
//  NetworkError.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines networking errors

public enum NetworkError: Error, LocalizedError {
    case unacceptableStatusCode(
        statusCode: HTTPStatusCode,
        acceptedStatusCodes: Range<HTTPStatusCode>,
        response: Response
    )
    case noStatusCode(response: Response)
    case invalidRequest(error: Error)
    case underlying(error: Error)
    case unknown

    public var errorDescription: String? {
        switch self {
        case let .unacceptableStatusCode(statusCode, range, _):
            return NSLocalizedString("Unaccepted status code \(statusCode), allowed range is \(range)", comment: "")
        case .noStatusCode:
            return NSLocalizedString("Response is missing status code", comment: "")
        case let .invalidRequest(error):
            return NSLocalizedString("Invalid request \(error.localizedDescription)", comment: "")
        case let .underlying(error):
            return NSLocalizedString("Network error \(error.localizedDescription)", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        }
    }
}
