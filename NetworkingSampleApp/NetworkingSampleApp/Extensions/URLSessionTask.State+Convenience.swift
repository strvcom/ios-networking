//
//  URLSessionTask.State+Convenience.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 21.12.2023.
//

import Foundation

extension URLSessionTask.State {
    var title: String {
        switch self {
        case .canceling: "cancelling"
        case .completed: "completed"
        case .running: "running"
        case .suspended: "suspended"
        @unknown default: ""
        }
    }
}
