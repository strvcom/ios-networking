//
//  AuthorizationTokenInterceptor.swift
//  
//
//  Created by Dominika Gajdová on 08.12.2022.
//

import Foundation

/// Defines the data the Authorization header is going to be containing.
/// In case of oAuth, it's going to be Bearer token
public protocol AuthorizationData {
    var header: String { get }
}

// MARK: AuthorizationToken
public struct AuthorizationToken: AuthorizationData {
    public let accessToken: String
    public let refreshToken: String
    public let expiryDate: Date?
    
    public var header: String {
        "Bearer \(accessToken)"
    }
}

// MARK: AuthorizationStorageManaging
public protocol AuthorizationStorageManaging {
    associatedtype AuthorizationData = AuthorizationToken
    
    func save(data: AuthorizationData) async
    func get() async -> AuthorizationData?
    func delete(data: AuthorizationData) async
}

// MARK: AuthorizationInMemoryStorage
public actor AuthorizationInMemoryStorage: AuthorizationStorageManaging {
    private var storage: AuthorizationData?
    
    public init() { }
    
    public func save(data: AuthorizationData) {
        storage = data
    }
    
    public func delete(data: AuthorizationData) {
        storage = nil
    }
    
    public func get() -> AuthorizationData? {
        storage
    }
}

// MARK: Needs to be implemented by end user.
public protocol AuthorizationManaging {
    var storage: any AuthorizationStorageManaging { get }
    func authorize(_ urlRequest: URLRequest) async throws -> URLRequest
    func refreshToken(_ token: String) async throws
}

extension AuthorizationManaging {
    var storage: any AuthorizationStorageManaging {
        // Default storage, there will be a keychain solution as default.
        AuthorizationInMemoryStorage()
    }
}

// MARK: - Defines authentication handling in requests
public final class AuthorizationTokenInterceptor: RequestInterceptor {
    private var authorizationManager: AuthorizationManaging
    
    public init(authorizationManager: AuthorizationManaging) {
        self.authorizationManager = authorizationManager
    }
    
    public func adapt(_ request: URLRequest, for endpointRequest: EndpointRequest) async throws -> URLRequest {
        guard endpointRequest.endpoint.isAuthenticationRequired else {
            return request
        }
        
        return try await authorizationManager.authorize(request)
    }
    
    public func process(_ response: Response, with urlRequest: URLRequest, for endpointRequest: EndpointRequest) async throws -> Response {
        
        return (Data(), URLResponse())
    }
}
