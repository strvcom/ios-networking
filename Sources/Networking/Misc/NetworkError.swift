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

    case unacceptableStatusCode(HTTPStatusCode, Range<HTTPStatusCode>, Response)
    case noStatusCode(Response)
    case invalidRequest(Error)
    case underlaying(Error)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        
        case .unacceptableStatusCode(let statusCode, let range, _):
            return NSLocalizedString("Unaccepted status code \(statusCode), allowed range is \(range)", comment: "")
        case .noStatusCode:
            return NSLocalizedString("Response is missing status code", comment: "")
        case .invalidRequest(let error):
            return NSLocalizedString("Invalid request \(error.localizedDescription)", comment: "")
        case .underlaying(let error):
            return NSLocalizedString("Network error \(error.localizedDescription)", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        }
    }
}
