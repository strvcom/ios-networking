//
//  AuthorizationInMemoryStorage.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public actor AuthorizationInMemoryStorage: AuthorizationStorageManaging {
    private var storage: AuthorizationData?
    
    public init() { }
    
    public func save(data: AuthorizationData) {
        storage = data
    }
    
    public func delete(data: AuthorizationData) {
        storage = nil
    }
    
    public func get() -> AuthorizationData? {
        storage
    }
}
