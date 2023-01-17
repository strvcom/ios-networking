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
    let delay: DelayConfiguration
    /// A handler which determines wether a request should be retried or not based on an error.
    /// By default errors with status codes `404, 500` are not being retried.
    let retryHandler: (Error) -> Bool

    public init(
        retries: Int,
        delay: DelayConfiguration,
        retryHandler: @escaping (Error) -> Bool
    ) {
        self.retries = retries
        self.delay = delay
        self.retryHandler = retryHandler
    }
    
    /// Default configuration ignores 404 and 500 status codes
    static var `default` = RetryConfiguration(
        retries: 3,
        delay: .constant(2)
    ) { error in
        guard let networkError = error as? NetworkError,
              case let .unacceptableStatusCode(statusCode, _, _) = networkError
        else {
            return true
        }

        return statusCode != 404 && statusCode != 500
    }
}

extension RetryConfiguration {
    /// A type that defines the delay strategy for retry logic.
    public enum DelayConfiguration {
        /// The delay cumulatively increases after each retry.
        case progressive(TimeInterval)
        /// The delay is the same after each retry.
        case constant(TimeInterval)
    }
}
