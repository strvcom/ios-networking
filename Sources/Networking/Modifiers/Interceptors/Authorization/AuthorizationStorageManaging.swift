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
    func saveData(_ data: AuthorizationData) async throws
    func getData() async throws -> AuthorizationData
    func deleteData() async throws
}
