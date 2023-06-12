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

    /// Currently ongoing upload tasks.
    var allTasks: [UploadTask] { get async }

    /// Initiates a data upload request for the specified endpoint.
    /// - Parameters:
    ///   - data: The data to send to the server.
    ///   - endpoint: The API endpoint to where data will be sent.
    /// - Returns: An `UploadTask` that represents this request.
    func upload(
        data: Data,
        to endpoint: Requestable
    ) async throws -> UploadTask

    /// Initiates a file upload request for the specified endpoint.
    /// - Parameters:
    ///   - fileUrl: The file's URL to send to the server.
    ///   - endpoint: The API endpoint to where data will be sent.
    /// - Returns: An `UploadTask` that represents this request.
    func upload(
        fromFile fileUrl: URL,
        to endpoint: Requestable
    ) async throws -> UploadTask

    /// Provides a stream of upload task's states for the specified `UploadTask.ID`.
    /// - Parameter uploadTaskId: The identifier of the task to observe.
    /// - Returns: An asynchronous stream of upload state.
    func stateStream(for uploadTaskId: UploadTask.ID) async -> StateStream

    /// Invalidates the session with the option to wait for all outstanding (active) tasks.
    ///
    /// The internal implementation uses Apple's delegate pattern which retains a strong reference to the delegate. You must call this method to allow the manager to be released from the memory, otherwise your app will be leaking until your app exits or the session is invalidated.
    /// - Parameter shouldFinishTasks: Determines whether all outstanding tasks should finish before invalidating the session or be immediately cancelled.
    func invalidateSession(shouldFinishTasks: Bool)
}
