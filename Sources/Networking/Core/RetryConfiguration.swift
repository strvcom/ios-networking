//
//  RetryConfiguration.swift
//
//
//  Created by Tomas Cejka on 23.09.2021.
//

import Foundation

public struct RetryConfiguration {
    let retries: Int
    let delay: TimeInterval
    let retryHandler: (Error) -> Bool

    // default configuration ignores
    static var `default` = RetryConfiguration(
        retries: 3,
        delay: 2
    ) { error in
        if let networkError = error as? NetworkError,
           case let .unacceptableStatusCode(statusCode, _, _) = networkError
        {
            switch statusCode {
            case 404, 500:
                return false
            default:
                break
            }
        }
        return true
    }
}
