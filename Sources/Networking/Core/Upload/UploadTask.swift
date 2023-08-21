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
    var task: URLSessionUploadTask

    /// The request associated with this task.
    let endpointRequest: EndpointRequest

    /// The uploadable data associated with this task.
    let uploadable: Uploadable

    /// Use this publisher to emit a new state of the task.
    let statePublisher: CurrentValueSubject<State, Never>

    /// The counter that counts number of retries for this task.
    let retryCounter: Counter

    /// The file manager associated with the task.
    let fileManager: FileManager
}

// MARK: - Public API
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
    
    func cleanup() async {
        await resetRetryCounter()

        if case let .file(url, removeOnComplete) = uploadable, removeOnComplete {
            try? fileManager.removeItem(at: url)
        }
    }
}

// MARK: - Internal API
extension UploadTask {
    /// The identifier of the underlying `URLSessionUploadTask`.
    var taskIdentifier: Int {
        task.taskIdentifier
    }

    /// An asynchronous sequence of the upload task' state.
    var stateStream: AsyncPublisher<AnyPublisher<UploadTask.State, Never>> {
        statePublisher.eraseToAnyPublisher().values
    }

    /// Completes the upload task by emitting the latest state and completing the state stream.
    /// - Parameters:
    ///   - state: The latest state to emit before completing the task.
    ///   - delay: The delay between the emitting the `state` and completion in nanoseconds. Defaults to 0.2 seconds.
    func complete(with state: State, delay: TimeInterval = 20_000_000) async {
        statePublisher.send(state)

        // Publishing value and completion one after another might cause the completion
        // cancelling the whole stream before the client can process the emitted value.
        try? await Task.sleep(nanoseconds: UInt64(delay))
        statePublisher.send(completion: .finished)
    }
    
    func resetRetryCounter() async {
        await retryCounter.reset(for: endpointRequest.id)
    }
}

extension UploadTask {
    init(
        sessionUploadTask: URLSessionUploadTask,
        endpointRequest: EndpointRequest,
        uploadable: Uploadable,
        fileManager: FileManager
    ) {
        self.task = sessionUploadTask
        self.endpointRequest = endpointRequest
        self.uploadable = uploadable
        self.statePublisher = .init(State(task: sessionUploadTask))
        self.retryCounter = Counter()
        self.fileManager = fileManager
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
