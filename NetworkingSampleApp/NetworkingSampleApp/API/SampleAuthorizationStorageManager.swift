//
//  SampleAuthorizationStorageManager.swift
//
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Networking

actor SampleAuthorizationStorageManager: AuthorizationStorageManaging {
    private var storage: AuthorizationData?
    
    func saveData(_ data: AuthorizationData) async throws {
        storage = data
    }
    
    func deleteData() async throws {
        storage = nil
    }
    
    func getData() async throws -> AuthorizationData {
        guard let storage = storage else {
            throw AuthorizationError.missingAuthorizationData
        }
        
        return storage
    }
}
