//
//  AuthorizationStorageManaging.swift
//
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

/// A definition of a manager which handles operations related to storing ``AuthorizationData`` for example in a KeyChain.
public protocol AuthorizationStorageManaging {
    func saveData(_ data: AuthorizationData) async throws
    func getData() async throws -> AuthorizationData
    func deleteData() async throws
}
