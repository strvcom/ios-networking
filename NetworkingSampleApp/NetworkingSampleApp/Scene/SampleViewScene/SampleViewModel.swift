//
//  SampleViewModel.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 06.12.2022.
//

import Foundation
import Networking

final class SampleViewModel {
    private let apiManager = APIManager(
        urlSession: URLSession.shared,
        errorProcessors: [SampleErrorProcessor()]
    )
    
    func runNetworkingExamples() {
        Task {
            do {
                //HTTP 200
                try await loadUserList()
                
                // HTTP 400
                try await login(email: "email@strv.com", password: nil)
            } catch let error as SampleAPIError {
                print(error.error ?? "Unknown")
            } catch {
                print(error)
            }
        }
    }
    
    func loadUserList() async throws {
        let response: SampleUsersResponse = try await apiManager.request(
            SampleUserRouter.users(page: 2)
        )
        print(response)
    }
    
    func login(email: String?, password: String?) async throws {
        let request = SampleUserAuthRequest(email: email, password: password)
        let response: SampleUserAuthResponse = try await apiManager.request(
            SampleUserRouter.loginUser(user: request)
        )
    }
}
