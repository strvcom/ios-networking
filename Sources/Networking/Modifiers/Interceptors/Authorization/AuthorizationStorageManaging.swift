//
//  AuthorizationStorageManaging.swift
//
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

/// A definition of a manager which handles operations related to storing ``AuthorizationData`` for example in a KeyChain.
/// To keep consistency all operations are async
@NetworkingActor
public protocol AuthorizationStorageManaging: Sendable {
    func saveData(_ data: AuthorizationData) async throws
    func getData() async throws -> AuthorizationData
    func deleteData() async throws
}
