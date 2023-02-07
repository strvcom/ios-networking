//
//  AuthorizationTokenInterceptorTests.swift
//  
//
//  Created by Matej Molnár on 02.02.2023.
//

@testable import Networking
import XCTest

// MARK: - Tests

final class AuthorizationTokenInterceptorTests: XCTestCase {
    let mockSessionId = "mockSessionId"
    
    func testSuccessfulRequestAuthorization() async throws {
        let authManager = MockAuthorizationManager()
        let authTokenInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        let validAuthData = AuthorizationData.makeValidAuthorizationData()
        
        try await authManager.storage.save(data: validAuthData)
        
        let requestable = MockRouter.testAuthenticationRequired
        let request = URLRequest(url: requestable.baseURL)
        let endpointRequest = EndpointRequest(requestable, sessionId: mockSessionId)
        
        let adaptedRequest = try await authTokenInterceptor.adapt(request, for: endpointRequest)
        
        XCTAssertEqual(adaptedRequest.allHTTPHeaderFields![HTTPHeader.HeaderField.authorization.rawValue], "Bearer \(validAuthData.accessToken)")
    }
    
    func testFailedRequestAuthorization() async throws {
        let authManager = MockAuthorizationManager()
        let authTokenInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        
        let requestable = MockRouter.testAuthenticationRequired
        let request = URLRequest(url: requestable.baseURL)
        let endpointRequest = EndpointRequest(requestable, sessionId: mockSessionId)
        
        do {
            _ = try await authTokenInterceptor.adapt(request, for: endpointRequest)
        } catch {
            XCTAssertEqual(error as! AuthorizationError, AuthorizationError.missingAuthorizationData)
        }
    }
    
    func testAuthenticationNotRequiredRequest() async throws {
        let authManager = MockAuthorizationManager()
        let authTokenInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        let validAuthData = AuthorizationData.makeValidAuthorizationData()
        
        try await authManager.storage.save(data: validAuthData)
        
        let requestable = MockRouter.testAuthenticationNotRequired
        let request = URLRequest(url: requestable.baseURL)
        let endpointRequest = EndpointRequest(requestable, sessionId: mockSessionId)
        
        let adaptedRequest = try await authTokenInterceptor.adapt(request, for: endpointRequest)
        
        XCTAssertNil(adaptedRequest.allHTTPHeaderFields?[HTTPHeader.HeaderField.authorization.rawValue])
    }
    
    func testSuccessfulTokenRefresh() async throws {
        let authManager = MockAuthorizationManager()
        let authTokenInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        let expiredAuthData = AuthorizationData.makeExpiredAuthorizationData()
        
        try await authManager.storage.save(data: expiredAuthData)
        
        let refreshedAuthData = AuthorizationData.makeValidAuthorizationData()
        
        authManager.refreshedAuthorizationData = refreshedAuthData
        
        let requestable = MockRouter.testAuthenticationRequired
        let request = URLRequest(url: requestable.baseURL)
        let endpointRequest = EndpointRequest(requestable, sessionId: mockSessionId)
        
        let adaptedRequest = try await authTokenInterceptor.adapt(request, for: endpointRequest)
        
        XCTAssertEqual(adaptedRequest.allHTTPHeaderFields![HTTPHeader.HeaderField.authorization.rawValue], "Bearer \(refreshedAuthData.accessToken)")
    }
    
    func testFailedTokenRefresh() async throws {
        let authManager = MockAuthorizationManager()
        let authTokenInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        let expiredAuthData = AuthorizationData.makeExpiredAuthorizationData()
        
        try await authManager.storage.save(data: expiredAuthData)
        
        let requestable = MockRouter.testAuthenticationRequired
        let request = URLRequest(url: requestable.baseURL)
        let endpointRequest = EndpointRequest(requestable, sessionId: mockSessionId)
        
        do {
            _ = try await authTokenInterceptor.adapt(request, for: endpointRequest)
        } catch {
            XCTAssertEqual(error as! AuthorizationError, AuthorizationError.expiredAccessToken)
        }
    }
    
    /// Creates multiple parallel requests with expired access token. Only the first request should start refreshing the token, other requests should wait until the token refresh finishes and then get adapted with the new valid access token.
    func testSuccessfulRefreshWithMultipleParallelRequests() async throws {
        let authManager = MockAuthorizationManager()
        let authTokenInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        let expiredAuthData = AuthorizationData.makeExpiredAuthorizationData()
        
        /// Token refresh is going to take 0.5 seconds in order to test wether other requests actually wait for the refresh to finish.
        authManager.sleepNanoseconds = 500_000_000
        try await authManager.storage.save(data: expiredAuthData)
        
        let refreshedAuthData = AuthorizationData.makeValidAuthorizationData()
        
        authManager.refreshedAuthorizationData = refreshedAuthData
        
        let requestable = MockRouter.testAuthenticationRequired
        let request = URLRequest(url: requestable.baseURL)
        let endpointRequest = EndpointRequest(requestable, sessionId: mockSessionId)
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0...5 {
                group.addTask {
                    do {
                        let request = try await authTokenInterceptor.adapt(request, for: endpointRequest)
                        XCTAssertEqual(request.allHTTPHeaderFields![HTTPHeader.HeaderField.authorization.rawValue], "Bearer \(refreshedAuthData.accessToken)")
                    } catch {
                        XCTAssert(false, "function shouldn't throw and error: \(error)")
                    }
                }
            }
        }
    }
    
    /// Creates multiple parallel requests with expired access token. Only the first request should start refreshing the token, other requests should wait until the token refresh fails and then all of them should throw expiredAccessToken error.
    func testFailedRefreshWithMultipleParallelRequests() async throws {
        let authManager = MockAuthorizationManager()
        let authTokenInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
        let expiredAuthData = AuthorizationData.makeExpiredAuthorizationData()
        
        /// Token refresh is going to take 0.5 seconds in order to test wether other requests actually wait for the refresh to finish.
        authManager.sleepNanoseconds = 500_000_000
        try await authManager.storage.save(data: expiredAuthData)
        
        let requestable = MockRouter.testAuthenticationRequired
        let request = URLRequest(url: requestable.baseURL)
        let endpointRequest = EndpointRequest(requestable, sessionId: mockSessionId)
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0...5 {
                group.addTask {
                    do {
                        _ = try await authTokenInterceptor.adapt(request, for: endpointRequest)
                        XCTAssert(false, "function didn't throw an error even though it should have")
                    } catch {
                        XCTAssertEqual(error as! AuthorizationError, AuthorizationError.expiredAccessToken)
                    }
                }
            }
        }
    }
}

// MARK: - Mock helper classes
private actor MockAuthorizationStorageManager: AuthorizationStorageManaging {
    private var storage: AuthorizationData?
    
    func save(data: AuthorizationData) async throws {
        storage = data
    }
    
    func deleteData() async throws {
        storage = nil
    }
    
    func get() async throws -> AuthorizationData {
        guard let storage = storage else {
            throw AuthorizationError.missingAuthorizationData
        }
        
        return storage
    }
}

private class MockAuthorizationManager: AuthorizationManaging {
    let storage: AuthorizationStorageManaging = MockAuthorizationStorageManager()
    
    var sleepNanoseconds: UInt64 = 0
    var refreshedAuthorizationData: AuthorizationData?
    
    func refreshAuthorizationData(with refreshToken: String) async throws -> Networking.AuthorizationData {
        try await Task.sleep(nanoseconds: sleepNanoseconds)
        
        if let refreshedAuthorizationData = refreshedAuthorizationData {
            return refreshedAuthorizationData
        } else {
            throw AuthorizationError.expiredAccessToken
        }
    }
}

private enum MockRouter: Requestable {
    case testAuthenticationRequired
    case testAuthenticationNotRequired
    
    var baseURL: URL {
        URL(string: "test.com")!
    }

    var path: String {
        "/test"
    }
    
    var isAuthenticationRequired: Bool {
        switch self {
        case .testAuthenticationRequired:
            return true
        case .testAuthenticationNotRequired:
            return false
        }
    }
}

// MARK: - Helper extensions
private extension AuthorizationData {
    static func makeValidAuthorizationData() -> AuthorizationData {
        .init(
            accessToken: "validAccessToken",
            refreshToken: "validRefreshToken",
            expiresIn: Date().addingTimeInterval(10),
            expirationOffset: 0
        )
    }
    
    static func makeExpiredAuthorizationData() -> AuthorizationData {
        .init(
            accessToken: "expiredAccessToken",
            refreshToken: "validRefreshToken",
            expiresIn: Date().addingTimeInterval(-10),
            expirationOffset: 0
        )
    }
}
