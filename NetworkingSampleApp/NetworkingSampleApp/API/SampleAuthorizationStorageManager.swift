//
//  SampleAuthorizationStorageManager.swift
//
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Networking

public actor SampleAuthorizationStorageManager: AuthorizationStorageManaging {
    private var storage: AuthorizationData?
    
    public init() { }
    
    public func save(data: AuthorizationData) async throws {
        storage = data
    }
    
    public func delete(data: AuthorizationData) async throws {
        storage = nil
    }
    
    public func get() async -> AuthorizationData? {
        storage
    }
}
