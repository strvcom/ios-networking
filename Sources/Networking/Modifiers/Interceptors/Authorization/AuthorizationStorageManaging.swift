//
//  AuthorizationStorageManaging.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public protocol AuthorizationStorageManaging {    
    func save(data: AuthorizationData) async throws
    func get() async throws -> AuthorizationData
    func deleteData() async throws
}
