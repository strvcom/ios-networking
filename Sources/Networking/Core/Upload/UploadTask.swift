//
//  UploadTask.swift
//
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation

/// Represents and manages an upload task and provides its state.
public struct UploadTask: Sendable {
    // swiftlint:disable:next type_name
    public typealias ID = String

    /// The session task this object represents.
    var task: URLSessionUploadTask

    /// The request associated with this task.
    let endpointRequest: EndpointRequest

    /// The uploadable data associated with this task.
    let uploadable: Uploadable

    /// An asynchronous sequence of the upload task' state.
    let stateStream: AsyncStream<State>

    /// Use this stream to emit a new state of the task
    let stateContinuation: AsyncStream<State>.Continuation
}

// MARK: - Public API
public extension UploadTask {
    /// Resumes the task.
    /// Has no effect if the task is not in the suspended state.
    func resume() {
        if task.state == .suspended {
            task.resume()
            stateContinuation.yield(State(task: task))
        }
    }

    /// Pauses the task.
    ///
    /// Call `resume()` to resume the upload.
    /// - Note: While paused (suspended state), the task is still subject to timeouts.
    func pause() {
        task.suspend()
        stateContinuation.yield(State(task: task))
    }

    /// Cancels the task.
    ///
    /// Calling this method will produce a `NSURLErrorCancelled` error
    /// and set the task to the `URLSessionTask.State.cancelled` state.
    func cancel() {
        task.cancel()
        stateContinuation.yield(State(task: task))
        stateContinuation.finish()
    }
    
    func cleanup() async {
        if case let .file(url, removeOnComplete) = uploadable, removeOnComplete {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Internal API
@available(iOS 15.0, *)
extension UploadTask {
    /// The identifier of the underlying `URLSessionUploadTask`.
    var taskIdentifier: Int {
        task.taskIdentifier
    }

    /// Completes the upload task by emitting the latest state and completing the state stream.
    /// - Parameters:
    ///   - state: The latest state to emit before completing the task.
    ///   - delay: The delay between the emitting the `state` and completion in nanoseconds. Defaults to 0.2 seconds.
    func complete(with state: State, delay: TimeInterval = 20_000_000) async {
        stateContinuation.yield(State(task: task))

        // Publishing value and completion one after another might cause the completion
        // cancelling the whole stream before the client can process the emitted value.
        try? await Task.sleep(nanoseconds: UInt64(delay))
        stateContinuation.finish()
    }
}

extension UploadTask {
    init(
        sessionUploadTask: URLSessionUploadTask,
        endpointRequest: EndpointRequest,
        uploadable: Uploadable
    ) {
        self.task = sessionUploadTask
        self.endpointRequest = endpointRequest
        self.uploadable = uploadable

        let (stream, continuation) = AsyncStream.makeStream(of: State.self)
        self.stateStream = stream
        self.stateContinuation = continuation
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
