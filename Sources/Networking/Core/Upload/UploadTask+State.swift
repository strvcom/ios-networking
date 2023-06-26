//
//  UploadTask+State.swift
//  
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation

public extension UploadTask {
    /// The upload task's state.
    struct State {
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

public extension UploadTask.State {
    /// The amount of data sent indicated by values from 0 to 1.
    var fractionCompleted: Double {
        totalBytes > 0 ? Double(sentBytes) / Double(totalBytes) : 0
    }

    var cancelled: Bool {
        (error as? URLError)?.code == .cancelled
    }

    var timedOut: Bool {
        (error as? URLError)?.code == .timedOut
    }

    var isRunning: Bool {
        taskState == .running
    }

    var isSuspended: Bool {
        taskState == .suspended
    }

    var isCanceling: Bool {
        taskState == .canceling
    }

    var isCompleted: Bool {
        taskState == .completed
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
