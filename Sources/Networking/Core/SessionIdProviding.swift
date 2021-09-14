//
//  SessionIdProviding.swift
//
//
//  Created by Tomas Cejka on 13.09.2021.
//

import Foundation

public protocol SessionIdProviding {
    var sessionId: String { get }
}

public extension SessionIdProviding {
    var sessionId: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMddyyyy_hhmmssa"
        // keep session id in readable format
        return dateFormatter.string(from: Date())
    }
}
