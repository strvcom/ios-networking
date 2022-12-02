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

    func testEmptyAcceptableStatuses() throws {
        // no error when empty acceptableStatusCodes
        let processor = StatusCodeProcessor()
        
        let mock1 = createMockResponseParams(MockRouter.emptyAcceptStatuses, statusCode: 404)
        try _ = processor.process(mock1.response, with: mock1.urlRequest, for: mock1.endpointRequest)
        
        
        let mock2 = createMockResponseParams(MockRouter.emptyAcceptStatuses, statusCode: 400)
        try _ = processor.process(mock2.response, with: mock2.urlRequest, for: mock2.endpointRequest)
        
        let mock3 = createMockResponseParams(MockRouter.emptyAcceptStatuses, statusCode: 200)
        try _ = processor.process(mock3.response, with: mock3.urlRequest, for: mock3.endpointRequest)
    }

    func testUnacceptableStatus1() {
        // error when status code not in acceptable statuses
        do {
            let mock = createMockResponseParams(MockRouter.regularAcceptStatuses, statusCode: 404)
            try _ = StatusCodeProcessor().process(mock.response, with: mock.urlRequest, for: mock.endpointRequest)
            XCTAssert(false, "function didn't throw an error even though it should have")
        } catch {
            var correctError = false
            if case NetworkError.unacceptableStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError, "function threw an incorrect error")
        }
    }
    
    func testUnacceptableStatus2() {
        // error when status code not in acceptable statuses
        do {
            let mock = createMockResponseParams(MockRouter.irregularAcceptStatuses, statusCode: 200)
            try _ = StatusCodeProcessor().process(mock.response, with: mock.urlRequest, for: mock.endpointRequest)
            XCTAssert(false, "function didn't throw an error even though it should have")
        } catch {
            var correctError = false
            if case NetworkError.unacceptableStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError, "function threw an incorrect error")
        }
    }

    func testNotHttpsURLResponse() {
        let mockEndpointRequest = EndpointRequest(MockRouter.regularAcceptStatuses, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: MockRouter.regularAcceptStatuses.baseURL)

        let mockURLResponse = URLResponse(url: MockRouter.regularAcceptStatuses.baseURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let mockResponse = (Data(), mockURLResponse)
        let statusProcessor = StatusCodeProcessor()

        do {
            _ = try statusProcessor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)
            XCTAssert(false, "function didn't throw an error even though it should have")
        } catch {
            var correctError = false
            if case NetworkError.noStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError, "function threw an incorrect error")
        }
    }

    static var allTests = [
        ("testEmptyAcceptableStatuses", testEmptyAcceptableStatuses),
        ("testUnacceptableStatus1", testUnacceptableStatus1),
        ("testUnacceptableStatus2", testUnacceptableStatus2),
        ("testNotHttpsURLResponse", testNotHttpsURLResponse)
    ]
}

// MARK: - Factory methods to create mock objects

private extension StatusCodeProcessorTests {
    func createMockResponseParams(
        _ router: MockRouter,
        statusCode: HTTPStatusCode
    ) -> (response: Response, urlRequest: URLRequest, endpointRequest: EndpointRequest) {
        let mockEndpointRequest = EndpointRequest(router, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: router.baseURL)
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: router.baseURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)

        return (mockResponse, mockURLRequest, mockEndpointRequest)
    }
}
