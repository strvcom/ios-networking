//
//  SessionIdProviding.swift
//
//
//  Created by Tomas Cejka on 05.10.2021.
//

import Foundation

// MARK: - Generates session id

/// A type that provides an identifier for network sessions.
protocol SessionIdProviding {
    var sessionId: String { get }
}

// MARK: - Default implementation for session id provider

/// Default implementation that works with readable data format for session id.
extension SessionIdProviding {
    /// A default session id created from current date in `"MMddyyyy_hhmmssa"` format.
    var sessionId: String {
        let dateFormatter = DateFormatter()
        // keep session id in readable format
        dateFormatter.dateFormat = "MMddyyyy_hhmmssa"
        return dateFormatter.string(from: Date())
    }
}

// MARK: - Session id provider

/// A default implementation of ``SessionIdProviding``.
struct SessionIdProvider: SessionIdProviding {}
