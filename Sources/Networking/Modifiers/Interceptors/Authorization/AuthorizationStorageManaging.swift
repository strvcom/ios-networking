//
//  AuthorizationStorageManaging.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

/// Basic operations to store `AuthorizationData`
/// To keep consistency all operations are async
public protocol AuthorizationStorageManaging {    
    func save(data: AuthorizationData) async throws
    func get() async throws -> AuthorizationData
    func deleteData() async throws
}
