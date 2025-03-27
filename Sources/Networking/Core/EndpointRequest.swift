//
//  EndpointRequest.swift
//  Networking
//
//  Created by Tomas Cejka on 04.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

/// A wrapper structure which contains API endpoint with additional info about the session within which it's being called and an API call identifier.
public struct EndpointRequest: Identifiable, Sendable {
    public let id: String
    public let sessionId: String
    public let endpoint: Requestable

    public init(_ endpoint: Requestable, sessionId: String) {
        id = "\(endpoint.identifier)_\(Date().timeIntervalSince1970)"
        self.endpoint = endpoint
        self.sessionId = sessionId
    }
}
