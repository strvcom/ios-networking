//
//  APIManagerTests.swift
//
//
//  Created by Matej Molnár on 28.12.2023.
//

@testable import Networking
import XCTest

@NetworkingActor
final class APIManagerTests: XCTestCase {
    enum UserRouter: Requestable {
        case users(page: Int)

        var baseURL: URL {
            // swiftlint:disable:next force_unwrapping
            URL(string: "https://reqres.in/api")!
        }

        var path: String {
            switch self {
            case .users:
                "users"
            }
        }

        var urlParameters: [String: Any]? {
            switch self {
            case let .users(page):
                ["page": page]
            }
        }

        var method: HTTPMethod {
            switch self {
            case .users:
                .get
            }
        }
    }

    private let mockSessionId = "2023-01-04T16:15:29Z"

    func testMultiThreadRequests() {
        let mockResponseProvider = MockResponseProvider(with: Bundle.module, sessionId: mockSessionId)
        let apiManager = APIManager(
            responseProvider: mockResponseProvider,
            // Since one of the mocked responses returns 400 we don't want the test fail.
            responseProcessors: []
        )

        let expectation = XCTestExpectation(description: "Requests completed")

        Task {
            // Create 15 parallel requests on multiple threads to test the manager's thread safety.
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<15 {
                    group.addTask {
                        try await apiManager.request(UserRouter.users(page: 2))
                    }
                }

                try await group.waitForAll()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }
}
