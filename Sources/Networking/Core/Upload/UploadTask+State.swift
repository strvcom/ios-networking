//
//  UploadTask+State.swift
//  
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation

extension UploadTask {
    /// The upload task's state.
    public struct State {
        /// Number of bytes sent.
        public let sentBytes: Int64

        /// Number of bytes expected to send.
        public let totalBytes: Int64

        /// An error produced by the task.
        public var error: Error?

        /// A response produced by the task.
        public var response: Response?

        /// The internal state of the `URLSessionTask`.
        let taskState: URLSessionTask.State
    }
}

extension UploadTask.State {
    /// Initializes the state from a `URLSessionTask`
    init(task: URLSessionTask) {
        sentBytes = task.countOfBytesSent
        totalBytes = task.countOfBytesExpectedToSend
        taskState = task.state
        error = task.error
    }
}

