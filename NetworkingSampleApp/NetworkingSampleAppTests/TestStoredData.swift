//
//  TestStoredData.swift
//  STRV_template Tests
//
//  Created by Tomas Cejka on 07.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Networking
@testable import NetworkingSampleApp
import XCTest

class TestStoredData: XCTestCase {
    private var apiManager: APIManaging?
    private lazy var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        apiManager = APIManager(
            network: SampleDataNetworking(with: Bundle(for: Self.self), sessionId: "04162021_103805AM"),
            requestAdapters: [LoggingInterceptor()],
            responseProcessors: [
                StatusCodeProcessor(),
                SampleAPIErrorProcessor(),
                LoggingInterceptor()
            ]
        )
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSampleDataNetworking() throws {
        let expectation = self.expectation(description: "Sample networking - get users request")

        // success expected, decode data model
        // swiftlint:disable:next force_unwrapping
        let userPublisher: AnyPublisher<SampleUsersResponse, Error> = apiManager!.request(
            SampleUserRouter.users(page: 2)
        )

        userPublisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail()
                    }
                    expectation.fulfill()
                }, receiveValue: { value in
                    XCTAssert(value.data.count == 6)
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 200, handler: nil)
    }
}
