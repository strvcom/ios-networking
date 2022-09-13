//
//  EndpointRequest.swift
//  Networking
//
//  Created by Tomas Cejka on 04.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Struct wrapping one call to the API endpoint

/// A wrapper structure which contains API endpoint with additional info about the session within which it's being called and an API call identifier.
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
