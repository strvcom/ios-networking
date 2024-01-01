//
//  File.swift
//
//
//  Created by Matej Molnár on 01.01.2024.
//

@testable import Networking
import XCTest

@NetworkingActor
final class UploadAPIManagerTests: XCTestCase {
    enum UploadRouter: Requestable {
        case mock

        var baseURL: URL {
            // swiftlint:disable:next force_unwrapping
            URL(string: "https://uploadAPIManager.tests")!
        }

        var path: String {
            "/mock"
        }

        var method: HTTPMethod {
            .post
        }
    }

    func testMultiThreadRequests2() async throws {
        let apiManager = UploadAPIManager(
            // A session configuration that uses no persistent storage for caches, cookies, or credentials.
            urlSessionConfiguration: .ephemeral
        )
        let data = Data("Test data".utf8)

        // Create 15 parallel requests on multiple threads to test the manager's thread safety.
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<15 {
                group.addTask {
                    _ = try await apiManager.upload(data: data, to: UploadRouter.mock)
                }
            }

            try await group.waitForAll()
        }
    }
}
