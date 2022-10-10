//
//  RetryConfiguration.swift
//
//
//  Created by Tomas Cejka on 23.09.2021.
//

import Foundation

/// Retry of API calls allows various options wrapped into `RetryConfiguration` struct.
public struct RetryConfiguration {
    /// The number of retries.
    let retries: Int
    /// The delay between each retry to avoid overwhelming API.
    let delay: TimeInterval
    /// A handler which determines wether a request should be retried or not based on an error.
    /// By default errors with status codes `404, 500` are not being retried.
    let retryHandler: (Error) -> Bool

    // default configuration ignores
    static var `default` = RetryConfiguration(
        retries: 3,
        delay: 2
    ) { error in
        guard let networkError = error as? NetworkError,
              case let .unacceptableStatusCode(statusCode, _, _) = networkError
        else {
            return true
        }

        return statusCode != 404 && statusCode != 500
    }
}
