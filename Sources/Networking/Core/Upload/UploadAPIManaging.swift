//
//  UploadAPIManaging.swift
//  
//
//  Created by Tony Ngo on 12.06.2023.
//

import Combine
import Foundation

public protocol UploadAPIManaging {
    typealias StateStream = AsyncPublisher<AnyPublisher<UploadTask.State, Never>>

    /// Currently active upload tasks.
    var activeTasks: [UploadTask] { get async }

    /// Initiates a data upload request for the specified endpoint.
    /// - Parameters:
    ///   - data: The data to send to the server.
    ///   - endpoint: The API endpoint to where data will be sent.
    ///   - retryConfiguration: An optional configuration for retry behavior.
    /// - Returns: An `UploadTask` that represents this request.
    func upload(
        data: Data,
        to endpoint: Requestable,
        retryConfiguration: RetryConfiguration?
    ) async throws -> UploadTask

    /// Initiates a file upload request for the specified endpoint.
    /// - Parameters:
    ///   - fileUrl: The file's URL to send to the server.
    ///   - endpoint: The API endpoint to where data will be sent.
    ///   - retryConfiguration: An optional configuration for retry behavior.
    /// - Returns: An `UploadTask` that represents this request.
    func upload(
        fromFile fileUrl: URL,
        to endpoint: Requestable,
        retryConfiguration: RetryConfiguration?
    ) async throws -> UploadTask

    /// Retries the upload task with the specified identifier.
    /// - Parameters:
    ///   - taskId: The upload task's identifier to retry.
    ///   - retryConfiguration: An optional configuration for retry behavior.
    func retry(taskId: String, retryConfiguration: RetryConfiguration?) async throws

    /// Provides a stream of upload task's states for the specified `UploadTask.ID`.
    ///
    /// The stream stops providing updates whenever the internal stream produces an error,
    /// i.e., `UploadTask.State.error` is non-nil. In such case, you can call `retry(taskId:)` to re-activate the stream for the specified `uploadTaskId`.
    /// - Parameter uploadTaskId: The identifier of the task to observe.
    /// - Returns: An asynchronous stream of upload state. If there is no such upload task the return stream finishes immediately.
    func stateStream(for uploadTaskId: UploadTask.ID) async -> StateStream

    /// Invalidates the session with the option to wait for all outstanding (active) tasks.
    ///
    /// The internal implementation uses Apple's delegate pattern which retains a strong reference to the delegate. You must call this method to allow the manager to be released from the memory, otherwise your app will be leaking until your app exits or the session is invalidated.
    /// - Parameter shouldFinishTasks: Determines whether all outstanding tasks should finish before invalidating the session or be immediately cancelled.
    func invalidateSession(shouldFinishTasks: Bool)
}

public extension UploadAPIManaging {
    /// Returns an active ``UploadTask`` specified by its identifier.
    func task(with id: UploadTask.ID) async -> UploadTask? {
        await activeTasks.first { $0.id == id }
    }
}
