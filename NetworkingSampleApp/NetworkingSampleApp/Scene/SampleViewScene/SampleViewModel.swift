//
//  SampleViewModel.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 06.12.2022.
//

import Foundation
import Networking
import OSLog

final class SampleViewModel {
    private let apiManager: APIManager = {
        let loggingInterceptor = LoggingInterceptor()
        
        return APIManager(
            urlSession: URLSession.shared,
            requestAdapters: [
                    loggingInterceptor,
                    AuthorizationTokenInterceptor(authorizationManager: self)
                ],
            responseProcessors: [
                    StatusCodeProcessor(), 
                    loggingInterceptor,
                    AuthorizationTokenInterceptor(authorizationManager: self)
                ],
            errorProcessors: [loggingInterceptor]
        )
    }()
    
    func runNetworkingExamples() {
        Task {
            do {
                //HTTP 200
                // try await loadUserList()
                
                // HTTP 400
//                try await login(
//                    email: SampleAPIConstants.validEmail,
//                    password: SampleAPIConstants.noPassword
//                )
                
                // HTTP 200/401
                try await loadSongList()                
            } catch {
                os_log("❌ Error while getting data: \(error)")                
            }
        }
    }
    
    func loadUserList() async throws {
        try await apiManager.request(
            SampleUserRouter.users(page: 2)
        )
    }
    
    func login(email: String?, password: String?) async throws {
        let request = SampleUserAuthRequest(email: email, password: password)
        try await apiManager.request(
            SampleUserRouter.loginUser(user: request)
        )
    }

    func loadSongList() async throws {
        let response: SampleSongsResponse = try await apiManager.request(
            SampleSongRouter.songs
        )
        
        for song in response {
            os_log("Title: %{public}@, Artist: %{public}@", log: OSLog.default, type: .info, song.title, song.artist)
        }
    }
}

// MARK: AuthorizationManaging
extension SampleViewModel: AuthorizationManaging {
    var storage: any AuthorizationStorageManaging {
        AuthorizationInMemoryStorage()
    }
    
    func authorize(_ urlRequest: URLRequest) async throws -> URLRequest {
        urlRequest
    }
    
    func refreshToken(_ token: String) async throws {
        
    }
}
