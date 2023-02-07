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
    func authorizeRequest(_ request: URLRequest) async throws -> URLRequest {
        let accessToken = try await getValidAccessToken()
        
        /// Append authentication header to request and return it.
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: HTTPHeader.HeaderField.authorization.rawValue
        )
        return mutableRequest
    }
    
    func refreshAuthorizationData() async throws {
        let refreshToken = try await storage.get().refreshToken
        let newAuthData = try await refreshAuthorizationData(with: refreshToken)
        
        try await storage.save(data: newAuthData)
    }
    
    func getValidAccessToken() async throws -> String {
        let authData = try await storage.get()
        
        guard !authData.isExpired else {
            throw AuthorizationError.expiredAccessToken
        }
        
        return authData.accessToken
    }
}
