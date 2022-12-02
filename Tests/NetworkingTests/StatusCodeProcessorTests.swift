//
//  StatusCodeProcessorTests.swift
//  
//
//  Created by Matej Molnár on 01.12.2022.
//

@testable import Networking
import XCTest

final class StatusCodeProcessorTests: XCTestCase {
    private let sessionId = "sessionId_status_code"

    enum MockRouter: Requestable {
        case emptyAcceptStatuses
        case regularAcceptStatuses
        case irregularAcceptStatuses

        var baseURL: URL {
            // swiftlint:disable:next force_unwrapping
            URL(string: "https://statuscodeprocessor.tests")!
        }

        var path: String {
            switch self {
            case .emptyAcceptStatuses:
                return "emptyAcceptStatuses"
            case .regularAcceptStatuses:
                return "regularAcceptStatuses"
            case .irregularAcceptStatuses:
                return "irregularAcceptStatuses"
            }
        }

        var acceptableStatusCodes: Range<HTTPStatusCode>? {
            switch self {
            case .emptyAcceptStatuses:
                return nil
            case .regularAcceptStatuses:
                return HTTPStatusCode.successAndRedirectCodes
            case .irregularAcceptStatuses:
                return 400 ..< 500
            }
        }
    }

    func testEmptyAcceptableStatuses() async throws {
        // no error when empty acceptableStatusCodes
        try await createMockResult(MockRouter.emptyAcceptStatuses, statusCode: 404)
        try await createMockResult(MockRouter.emptyAcceptStatuses, statusCode: 400)
        try await createMockResult(MockRouter.emptyAcceptStatuses, statusCode: 200)
    }

    func testNotInAcceptableStatuses() async {
        // error when status code not in acceptable statuses
        do {
            try await createMockResult(MockRouter.regularAcceptStatuses, statusCode: 404)
            XCTAssert(false)
        } catch {
            var correctError = false
            if case NetworkError.unacceptableStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError)
        }
        
        // error when status code not in acceptable statuses
        do {
            try await createMockResult(MockRouter.irregularAcceptStatuses, statusCode: 200)
            XCTAssert(false)
        } catch {
            var correctError = false
            if case NetworkError.unacceptableStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError)
        }
    }

    func testNotHttpsURLResponse() async {
        let mockEndpointRequest = EndpointRequest(MockRouter.regularAcceptStatuses, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: MockRouter.regularAcceptStatuses.baseURL)

        let mockURLResponse = URLResponse(url: MockRouter.regularAcceptStatuses.baseURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let mockResponse = (Data(), mockURLResponse)
        let statusProcessor = StatusCodeProcessor()

        do {
            _ = try statusProcessor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)
            XCTAssert(false)
        } catch {
            var correctError = false
            if case NetworkError.noStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError)
        }
    }

    static var allTests = [
        ("testEmptyAcceptableStatuses", testEmptyAcceptableStatuses),
        ("testNotInAcceptableStatuses", testNotInAcceptableStatuses),
        ("testNotHttpsURLResponse", testNotHttpsURLResponse)
    ]
}

// MARK: - Factory methods to create mock objects

private extension StatusCodeProcessorTests {
    @discardableResult
    func createMockResult(_ router: MockRouter, statusCode: HTTPStatusCode) async throws -> Response {
        let mockEndpointRequest = EndpointRequest(router, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: router.baseURL)
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: router.baseURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)

        return try StatusCodeProcessor().process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)
    }
}
