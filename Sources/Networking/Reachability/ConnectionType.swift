//
//  ConnectionType.swift
//
//  Created by Tomas Cejka on 14.03.2021.
//

import Foundation

// MARK: - Defines connection types

/// A network connection type.
public enum ConnectionType: CustomStringConvertible {
    case unavailable, wifi, cellular

    public var description: String {
        switch self {
        case .cellular: return "Cellular"
        case .wifi: return "WiFi"
        case .unavailable: return "No Connection"
        }
    }
}
