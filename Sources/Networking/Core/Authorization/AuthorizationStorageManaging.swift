//
//  AuthorizationStorageManaging.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public protocol AuthorizationStorageManaging {
    associatedtype AuthorizationData = AuthorizationToken
    
    func save(data: AuthorizationData) async
    func get() async -> AuthorizationData?
    func delete(data: AuthorizationData) async
}
