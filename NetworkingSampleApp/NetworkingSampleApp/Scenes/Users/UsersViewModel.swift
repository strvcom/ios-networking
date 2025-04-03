//
//  UsersViewModel.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 07.12.2023.
//

import Foundation
import Networking

@MainActor
final class UsersViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var createdUser: SampleCreateUserResponse?
    
    /// Custom decoder needed for decoding `createdAt` parameter of SampleCreateUserResponse.
    private let responseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()

    @NetworkingActor
    private lazy var apiManager: APIManager = {
        var responseProcessors: [ResponseProcessing] = [
            LoggingInterceptor.shared,
            StatusCodeProcessor.shared
        ]
        var errorProcessors: [ErrorProcessing] = [LoggingInterceptor.shared]

#if DEBUG
        responseProcessors.append(EndpointRequestStorageProcessor.shared)
        errorProcessors.append(EndpointRequestStorageProcessor.shared)
#endif

        return APIManager(
            requestAdapters: [LoggingInterceptor.shared],
            responseProcessors: responseProcessors,
            errorProcessors: errorProcessors
        )
    }()
}

extension UsersViewModel {
    func getUsers(in range: ClosedRange<Int>, parallelFetch: Bool) {
        Task {
            users = []

            if parallelFetch {
                // Fire all user requests parallelly in a group, assign it to users array after all of them are completed.
                users = try await withThrowingTaskGroup(of: User.self) { group in
                    for id in range {
                        group.addTask {
                            let response: SampleUserResponse = try await self.apiManager.request(SampleUserRouter.user(userId: id))
                            return response.data
                        }
                    }

                    var results = [User]()

                    for try await value in group {
                        results.append(value)
                    }

                    return results
                }
            } else {
                // Fetch user add it to users array and wait for 0.5 seconds, before fetching the next one.
                for id in range {
                    let response: SampleUserResponse = try await apiManager.request(SampleUserRouter.user(userId: id))
                    users.append(response.data)
                    try await Task.sleep(for: .seconds(0.5))
                }
            }
        }
    }

    func createUser(name: String, job: String) {
        Task {
            createdUser = try await self.apiManager.request(
                SampleUserRouter.createUser(user: .init(name: name, job: job)),
                decoder: responseDecoder,
                retryConfiguration: .default
            )
        }
    }
}
