//
//  AuthorizationManaging.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public protocol AuthorizationManaging {
    var storage: any AuthorizationStorageManaging { get }    
    func refreshToken(_ token: String) async throws -> AuthorizationData
}
