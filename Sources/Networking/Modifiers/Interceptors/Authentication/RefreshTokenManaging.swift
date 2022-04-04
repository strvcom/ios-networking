//
//  RefreshTokenManaging.swift
//
//  Created by Tomas Cejka on 22.03.2021.
//

import Combine
import Foundation

// MARK: - Defines authentication managing by refresh token

/*
 /// Authentication via refresh token to renew authentication token which is used to authorize requests
 public protocol RefreshTokenManaging: AnyObject, AuthenticationManaging {
     var authenticationToken: String? { get }
     var authenticationTokenExpirationDate: Date? { get }
     var refreshToken: String? { get }
     var refreshTokenExpirationDate: Date? { get }

     // custom header field for authorization
     /// <#Description#>
     var headerField: String { get }
     /// <#Description#>
     var isExpired: Bool { get }

     /// <#Description#>
     var refreshAuthenticationTokenManager: RefreshAuthenticationTokenManaging { get }

     // allows set authentication data from outside
     /// <#Description#>
     func store(_ authenticationTokenData: RefreshTokenData)
 }

 // MARK: - Default implementation for authentication token managing

 public extension RefreshTokenManaging {
     /// <#Description#>
     var headerField: String {
         "Authorization"
     }

     /// <#Description#>
     var isAuthenticated: Bool {
         authenticationToken != nil && !isExpired
     }

     /// <#Description#>
     var isExpired: Bool {
         guard let authenticationTokenExpirationDate = authenticationTokenExpirationDate else {
             return true
         }
         return authenticationTokenExpirationDate <= Date()
     }

     /// <#Description#>
     /// - Returns: <#description#>
     func authenticate() -> AnyPublisher<Void, AuthenticationError> {
         guard let refreshToken = refreshToken else {
             return Fail(error: .missingRefreshToken).eraseToAnyPublisher()
         }

         if let authenticationTokenExpirationDate = authenticationTokenExpirationDate,
            authenticationTokenExpirationDate <= Date()
         {
             // swiftlint:disable:previous opening_brace
             return Fail(error: .expiredRefreshToken).eraseToAnyPublisher()
         }

         return refreshAuthenticationTokenManager
             .refreshAuthenticationToken(refreshToken)
             .handleEvents(receiveOutput: { [weak self] authenticationTokenData in
                 self?.store(authenticationTokenData)
             })
             .map { _ in }
             .eraseToAnyPublisher()
     }
 }

 // MARK: - AuthenticationTokenManaging & AuthenticationProviding

 public extension RefreshTokenManaging where Self: RequestAuthorizing {
     /// <#Description#>
     /// - Parameter request: <#request description#>
     /// - Returns: <#description#>
     func authorize(_ request: URLRequest) -> Result<URLRequest, AuthenticationError> {
         guard isAuthenticated,
               let authenticationToken = authenticationToken
         else {
             guard authenticationToken == nil else {
                 return .failure(.expiredAuthenticationToken)
             }

             return .failure(.missingAuthenticationToken)
         }

         var authenticatedRequest = request
         authenticatedRequest.setValue(authenticationToken, forHTTPHeaderField: headerField)

         return .success(authenticatedRequest)
     }
 }
 */
