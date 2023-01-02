//
//  AuthorizationManaging.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

public protocol AuthorizationManaging {
    var storage: any AuthorizationStorageManaging { get }
    func authorize(_ urlRequest: URLRequest) async throws -> URLRequest
    func refreshToken(_ token: String) async throws
}

extension AuthorizationManaging {
    // Default authorize implementation.
    public func authorize(_ urlRequest: URLRequest) async throws -> URLRequest {
        if let authData = await storage.get(), !authData.isExpired {
            // append authentication header to request and return it
            var mutableRequest = urlRequest
            mutableRequest.setValue(
                authData.header,
                forHTTPHeaderField: HTTPHeader.HeaderField.authorization.rawValue
            )
            return mutableRequest
        }        
        
        return urlRequest
    }
}
