//
//  SampleAuthorizationStorageManager.swift
//
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Networking

actor SampleAuthorizationStorageManager: AuthorizationStorageManaging {
    private var storage: AuthorizationData?
    
    func save(data: AuthorizationData) async throws {
        storage = data
    }
    
    func delete(data: AuthorizationData) async throws {
        storage = nil
    }
    
    func get() async -> AuthorizationData? {
        storage
    }
}
