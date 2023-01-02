//
//  SampleAuthorizationManager.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Networking

final class SampleAuthorizationManager: AuthorizationManaging {
    let storage: AuthorizationStorageManaging
    
    init() {
        storage = AuthorizationInMemoryStorage()
    }
    
    func refreshToken(_ token: String) async throws {
        print("Refreshing...")
    }
}
