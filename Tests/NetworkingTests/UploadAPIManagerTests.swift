//
//  UploadAPIManagerTests.swift
//
//
//  Created by Matej Molnár on 01.01.2024.
//

@testable import Networking
import XCTest

@NetworkingActor
@available(iOS 15.0, *)
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

    func testMultiThreadRequests() {
        let apiManager = UploadAPIManager(
            // A session configuration that uses no persistent storage for caches, cookies, or credentials.
            urlSessionConfiguration: .ephemeral
        )
        let data = Data("Test data".utf8)
        let expectation = XCTestExpectation(description: "Uploads completed")

        Task {
            do {
                // Create 15 parallel requests on multiple threads to test the manager's thread safety.
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for _ in 0..<15 {
                        group.addTask {
                            _ = try await apiManager.upload(
                                .data(data, contentType: "text"),
                                to: UploadRouter.mock
                            )
                        }
                    }

                    try await group.waitForAll()
                    expectation.fulfill()
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [expectation], timeout: 1)
    }
}
