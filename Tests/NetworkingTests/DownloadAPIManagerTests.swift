//
//  DownloadAPIManagerTests.swift
//
//
//  Created by Matej Molnár on 01.01.2024.
//

@testable import Networking
import XCTest

@NetworkingActor
final class DownloadAPIManagerTests: XCTestCase {
    enum DownloadRouter: Requestable {
        case download(url: URL)

        var baseURL: URL {
            switch self {
            case let .download(url):
                url
            }
        }

        var path: String {
            switch self {
            case .download:
                ""
            }
        }
    }
    
    func testMultiThreadRequests() {
        let apiManager = DownloadAPIManager(
            // A session configuration that uses no persistent storage for caches, cookies, or credentials.
            urlSessionConfiguration: .ephemeral,
            // Set empty response processors since the mock download requests return status code 0 and we don't want the test fail.
            responseProcessors: []
        )

        // We can simulate the download even with a local file.
        guard let downloadUrl = Bundle.module.url(forResource: "download_test", withExtension: "txt") else {
            XCTFail("Resource not found")
            return
        }
        
        let expectation = XCTestExpectation(description: "Downloads completed")

        Task {
            // Create 15 parallel requests on multiple threads to test the manager's thread safety.
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for _ in 0..<15 {
                        group.addTask {
                            _ = try await apiManager.downloadRequest(
                                DownloadRouter.download(url: downloadUrl),
                                retryConfiguration: nil
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
