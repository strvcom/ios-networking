//
//  AuthorizationManaging.swift
//
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

/** A definition of manager which authorizes requests and manages refresh token mechanism.

 This manager requires you to provide a storage defined by ``AuthorizationStorageManaging`` (where OAuth credentials will be stored) and a ``refreshAuthorizationData(with:)`` method that will perform the refresh token network call to obtain a new OAuth pair. This should be handled on a separate ``APIManager`` instance which doesn't inject ``AuthorizationTokenInterceptor`` in order to avoid a dead loop.

 Optionally, you can provide custom implementations for ``authorizeRequest(_:)`` (by default, this method sets the authorization header) or ``getValidAccessToken()`` (by default, this method returns the access token saved in provided storage).

 Example implementation:
 ```swift
 final class AuthorizationManager: AuthorizationManaging {
     let storage: AuthorizationStorageManaging = AuthorizationStorageManager()

     private let apiManager: APIManager = APIManager()

     func refreshAuthorizationData(with refreshToken: String) async throws -> Networking.AuthorizationData {
         let request = RefreshTokenRequest(refreshToken: refreshToken)
         let response: AuthResponse = try await apiManager.request(
             AuthRouter.refreshToken(request)
         )
         return response.authData
     }
 }
 ```
 */
public protocol AuthorizationManaging {
    var storage: any AuthorizationStorageManaging { get }
    
    func refreshAuthorizationData(with refreshToken: String) async throws -> AuthorizationData
    func authorizeRequest(_ request: URLRequest) async throws -> URLRequest
    func getValidAccessToken() async throws -> String
}

public extension AuthorizationManaging {
    func authorizeRequest(_ request: URLRequest) async throws -> URLRequest {
        let accessToken = try await getValidAccessToken()
        
        // Append authentication header to request and return it.
        var mutableRequest = request
        mutableRequest.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: HTTPHeader.HeaderField.authorization.rawValue
        )
        return mutableRequest
    }
    
    func refreshAuthorizationData() async throws {
        let refreshToken = try await storage.getData().refreshToken
        let newAuthData = try await refreshAuthorizationData(with: refreshToken)
        
        try await storage.saveData(newAuthData)
    }
    
    func getValidAccessToken() async throws -> String {
        let authData = try await storage.getData()
        
        guard !authData.isExpired else {
            throw AuthorizationError.expiredAccessToken
        }
        
        return authData.accessToken
    }
}
