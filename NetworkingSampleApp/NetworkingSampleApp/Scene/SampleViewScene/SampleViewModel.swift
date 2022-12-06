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
    private let apiManager = APIManager(
        urlSession: URLSession.shared,
        responseProcessors: [StatusCodeProcessor()],
        errorProcessors: [SampleErrorProcessor()]
    )
    
    func runNetworkingExamples() {
        Task {
            do {
                //HTTP 200
                try await loadUserList()
                
                // HTTP 400
                try await login(
                    email: SampleAPIConstants.validEmail,
                    password: SampleAPIConstants.noPassword
                )
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
            SampleUserRouter.loginUser(user: request)
        )
        os_log("Id: %{public}@, Email: %{public}@", log: OSLog.default, type: .info, response.id, response.email ?? "Unknown email")
    }
}
