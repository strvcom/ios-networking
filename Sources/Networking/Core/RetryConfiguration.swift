//
//  RetryConfiguration.swift
//
//
//  Created by Tomas Cejka on 23.09.2021.
//

import Foundation

/// Retry of API calls allows various options wrapped into `RetryConfiguration` struct
public struct RetryConfiguration {
    /// Number of retries
    let retries: Int
    /// Delay between each retry to avoid overwhelming API
    let delay: TimeInterval
    /// Customization providing error to bool in case error should be retried, by default `404, 500` are not retried
    let retryHandler: (Error) -> Bool

    // default configuration ignores
    static var `default` = RetryConfiguration(
        retries: 3,
        delay: 2
    ) { error in
        if
            let networkError = error as? NetworkError,
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
