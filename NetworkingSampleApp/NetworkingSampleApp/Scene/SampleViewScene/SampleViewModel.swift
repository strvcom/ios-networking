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
    private lazy var apiManager = APIManager(
        urlSession: URLSession.shared,
        requestAdapters: [
            // AuthorizationTokenInterceptor(authorizationManager: self)
        ],
        responseProcessors: [
            // AuthorizationTokenInterceptor(authorizationManager: self)
        ],
        errorProcessors: [
            SampleErrorProcessor()
        ]
    )
    
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
                
            } catch let error as SampleAPIError {
                os_log("❌ Custom error thrown: \(error)")
            } catch {
                os_log("❌ Error while getting data: \(error)")
            }
        }
    }
    
    func loadUserList() async throws {
        let response: SampleUsersResponse = try await apiManager.request(
            SampleUserRouter.users(page: 2)
        )
        os_log("Data: %{public}@, Page: %d", log: OSLog.default, type: .info, response.data, response.page)
    }
    
    func login(email: String?, password: String?) async throws {
        let request = SampleUserAuthRequest(email: email, password: password)
        let response: SampleUserResponse = try await apiManager.request(
            SampleSongRouter.loginUser(user: request)
        )
        os_log("Id: %{public}@, Email: %{public}@", log: OSLog.default, type: .info, response.id, response.email ?? "Unknown email")
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
