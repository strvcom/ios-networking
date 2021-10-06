//
//  SessionIdProviding.swift
//
//
//  Created by Tomas Cejka on 05.10.2021.
//

import Foundation

// MARK: - Generates session Id
protocol SessionIdProviding {
    var sessionId: String { get }
}

// MARK: - Default implementation for session id provider

extension SessionIdProviding {
    var sessionId: String {
        let dateFormatter = DateFormatter()
        // keep session id in readable format
        dateFormatter.dateFormat = "MMddyyyy_hhmmssa"
        return dateFormatter.string(from: Date())
    }
}

// MARK: - Session id provider

struct SessionIdProvider: SessionIdProviding {}
