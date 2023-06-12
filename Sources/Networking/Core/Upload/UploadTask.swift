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
    /// The session task this object represents.
    let task: URLSessionUploadTask

    /// The request associated with this task.
    let endpointRequest: EndpointRequest

    /// Use this publisher to emit a new state of the task.
    let statePublisher: CurrentValueSubject<State, Never>
}
