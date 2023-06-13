//
//  UploadTask.swift
//  
//
//  Created by Tony Ngo on 12.06.2023.
//

import Combine
import Foundation

/// Represents and manages an upload task and provides its state.
public struct UploadTask {
    public typealias ID = String

    /// The session task this object represents.
    let task: URLSessionUploadTask

    /// The request associated with this task.
    let endpointRequest: EndpointRequest

    /// The uploadable data associated with this task.
    let uploadable: Uploadable

    /// Use this publisher to emit a new state of the task.
    let statePublisher: CurrentValueSubject<State, Never>

    /// The counter that counts number of retries for this task.
    let retryCounter: Counter
}

public extension UploadTask {
    /// Resumes the task.
    /// Has no effect if the task is not in the suspended state.
    func resume() {
        if task.state == .suspended {
            task.resume()
            statePublisher.send(State(task: task))
        }
    }

    /// Pauses the task.
    ///
    /// Call `resume()` to resume the upload.
    /// - Note: While paused (suspended state), the task is still subject to timeouts.
    func pause() {
        task.suspend()
        statePublisher.send(State(task: task))
    }

    /// Cancels the task.
    ///
    /// Calling this method will produce a `NSURLErrorCancelled` error
    /// and set the task to the `URLSessionTask.State.cancelled` state.
    func cancel() {
        task.cancel()
        statePublisher.send(State(task: task))
    }
}

extension UploadTask {
    /// The identifier of the underlying `URLSessionUploadTask`.
    var taskIdentifier: Int {
        task.taskIdentifier
    }

    /// An asynchronous sequence of the upload task' state.
    var stateStream: AsyncPublisher<AnyPublisher<UploadTask.State, Never>> {
        statePublisher.eraseToAnyPublisher().values
    }
}

// MARK: - Retryable
extension UploadTask: Retryable {
    func sleepIfRetry(for error: Error, retryConfiguration: RetryConfiguration?) async throws {
        try await sleepIfRetry(
            for: error,
            endpointRequest: endpointRequest,
            retryConfiguration: retryConfiguration
        )
    }

    func resetRetryCounter() async {
        await retryCounter.reset(for: endpointRequest.id)
    }
}

// MARK: - Identifiable
extension UploadTask: Identifiable {
    /// An unique task identifier.
    ///
    /// The identifier value is equal to the internal request's identifier that this task is associated with.
    public var id: ID {
        endpointRequest.id
    }
}
