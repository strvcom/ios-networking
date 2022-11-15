//
//  EndpointRequest.swift
//  Networking
//
//  Created by Tomas Cejka on 04.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Struct wrapping one call to the API endpoint

/// Wrapper structure which contains called API endpoint definition with additional info about session within it's been called
public struct EndpointRequest: Identifiable {
    public let identifier: String
    public let sessionId: String
    public let endpoint: Requestable

    init(_ endpoint: Requestable, sessionId: String) {
        identifier = "\(endpoint.identifier)_\(Date().timeIntervalSince1970)"
        self.endpoint = endpoint
        self.sessionId = sessionId
    }
}
