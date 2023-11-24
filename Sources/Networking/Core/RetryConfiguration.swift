//
//  RetryConfiguration.swift
//
//
//  Created by Tomas Cejka on 23.09.2021.
//

import Foundation

/// Retry of API calls allows various options wrapped into `RetryConfiguration` struct.
public struct RetryConfiguration: Sendable {
    /// The number of retries.
    let retries: Int
    /// The delay between each retry to avoid overwhelming API.
    let delay: DelayConfiguration
    /// A handler which determines wether a request should be retried or not based on an error.
    /// By default errors with status codes `HTTPStatusCode.nonRetriableCodes` are not being retried.
    let retryHandler: @Sendable (Error) -> Bool

    public init(
        retries: Int,
        delay: DelayConfiguration,
        retryHandler: @Sendable @escaping (Error) -> Bool) {
        self.retries = retries
        self.delay = delay
        self.retryHandler = retryHandler
    }
    
    // default configuration ignores
    public static var `default`: RetryConfiguration {
        .init(
            retries: 3,
            delay: .constant(2)
        ) { error in
            /// Do not retry authorization errors.
            if error is AuthorizationError {
                return false
            }

            /// But retry certain HTTP errors.
            guard let networkError = error as? NetworkError,
                  case let .unacceptableStatusCode(statusCode, _, _) = networkError
            else {
                return true
            }

            return !(HTTPStatusCode.nonRetriableCodes ~= statusCode)
        }
    }
}

public extension RetryConfiguration {
    /// A type that defines the delay strategy for retry logic.
    enum DelayConfiguration : Sendable {
        /// The delay cumulatively increases after each retry.
        case progressive(TimeInterval)
        /// The delay is the same after each retry.
        case constant(TimeInterval)
    }
}
