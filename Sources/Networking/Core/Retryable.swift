//
//  Retryable.swift
//  
//
//  Created by Dominika Gajdová on 09.05.2023.
//

/// Provides retry utility functionality to subjects that require it.
protocol Retryable {
    /// Keeps count of executed retries so far given by `RetryConfiguration.retries`.
    var retryCounter: Counter { get }
        
    /// Determines whether request should be retried based on `RetryConfiguration.retryHandler`,
    /// otherwise suspends for a given time interval given by `DelayConfiguration`.
    /// If the retries count hits limit or the request should not be retried, it throws the original error.
    /// - Parameters:
    ///   - error: Initial error thrown by the attempted url request.
    ///   - endpointRequest: The endpoint describing the url request.
    ///   - retryConfiguration: Retry configuration for the given url request.
    func sleepIfRetry(
        for error: Error,
        endpointRequest: EndpointRequest,
        retryConfiguration: RetryConfiguration?
    ) async throws
}

extension Retryable {
    func sleepIfRetry(for error: Error, endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) async throws {
        let retryCount = await retryCounter.count(for: endpointRequest.id)
        
        guard
            let retryConfiguration = retryConfiguration,
            retryConfiguration.retryHandler(error),
            retryConfiguration.retries > retryCount
        else {
            /// reset retry count
            await retryCounter.reset(for: endpointRequest.id)
            throw error
        }
                
        /// count the delay for retry
        await retryCounter.increment(for: endpointRequest.id)
        
        var sleepDuration: UInt64
        switch retryConfiguration.delay {
        case .constant(let timeInterval):
            sleepDuration = UInt64(timeInterval) * 1_000_000_000
        case .progressive(let timeInterval):
            sleepDuration = UInt64(timeInterval) * UInt64(retryCount) * 1_000_000_000
        }
        
        try await Task.sleep(nanoseconds: sleepDuration)
    }
}
