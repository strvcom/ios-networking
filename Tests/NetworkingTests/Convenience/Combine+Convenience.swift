//
//  File.swift
//  
//
//  Created by Tomas Cejka on 15.04.2021.
//

import Foundation
import Combine
import XCTest

// MARK: Extension provides option to test output value in combine stream

extension Publisher where Output: Equatable {
    func assertOutput(matches: [Output], expectation: XCTestExpectation) -> AnyCancellable {
        var expectedValues = matches

        return sink(receiveCompletion: { _ in
        }, receiveValue: { value in
            guard let expectedValue = expectedValues.first else {
                XCTFail("The publisher emitted more values than expected.")
                return
            }

            guard expectedValue == value else {
                XCTFail("Expected received value \(value) to match first expected value \(expectedValue)")
                return
            }

            expectedValues = Array(expectedValues.dropFirst())

            if expectedValues.isEmpty {
                expectation.fulfill()
            }
        })
    }
}

// MARK: Extension provides option write test in async/await style

extension XCTestCase {
    func awaitCompletion<P: Publisher>(for publisher: P) -> Result<[P.Output], P.Failure> {
        let finishedExpectation = expectation(description: "completion expectation")
        var output = [P.Output]()
        var result: Result<[P.Output], P.Failure>!

        _ = publisher.sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                result = .failure(error)
            } else {
                result = .success(output)
            }

            finishedExpectation.fulfill()
        }, receiveValue: { value in
            output.append(value)
        })

        waitForExpectations(timeout: 1.0, handler: nil)

        return result
    }
}
