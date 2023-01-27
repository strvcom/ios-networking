//
//  AuthorizationManaging.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public protocol AuthorizationManaging {
    var storage: any AuthorizationStorageManaging { get }
    
    func refreshAuthorizationData(with refreshToken: String) async throws -> AuthorizationData
    func authorizeRequest(_ request: URLRequest) async throws -> URLRequest
}

public extension AuthorizationManaging {
    func refreshAuthorizationData() async throws {
        guard let refreshToken = await storage.get()?.refreshToken else {
            throw AuthorizationError.missingRefreshToken
        }
        
        let authData = try await refreshAuthorizationData(with: refreshToken)
        
        try await storage.save(data: authData)
    }
    
    func authorizeRequest(_ request: URLRequest) async throws -> URLRequest {
        guard let authData = await storage.get() else {
            throw AuthorizationError.missingAccessToken
        }
        
        guard !authData.isExpired else {
            throw AuthorizationError.expiredAccessToken
        }
        
        /// Append authentication header to request and return it.
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(authData.accessToken)",
            forHTTPHeaderField: HTTPHeader.HeaderField.authorization.rawValue
        )
        return mutableRequest
    }
}
