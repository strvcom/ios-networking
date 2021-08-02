import Combine
@testable import Networking
import XCTest

final class StatusCodeProcessorTests: XCTestCase {
    enum MockRouter: Requestable {
        case emptyAcceptStatuses
        case regularAcceptStatuses
        case iregularAcceptStatuses

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
            case .iregularAcceptStatuses:
                return "iregularAcceptStatuses"
            }
        }

        var acceptableStatusCodes: Range<HTTPStatusCode>? {
            switch self {
            case .emptyAcceptStatuses:
                return nil
            case .regularAcceptStatuses:
                return HTTPStatusCode.successAndRedirectCodes
            case .iregularAcceptStatuses:
                return 400..<500
            }
        }
    }

    func testEmptyAcceptableStatuses() {
        // no error when empty acceptableStatusCodes
        let testNotFound = createMockResult(MockRouter.emptyAcceptStatuses, statusCode: 404)
        XCTAssertNoThrow(try testNotFound.get())

        // no error when empty acceptableStatusCodes
        let testBadRequest = createMockResult(MockRouter.emptyAcceptStatuses, statusCode: 400)
        XCTAssertNoThrow(try testBadRequest.get())

        // no error when empty acceptableStatusCodes
        let testSuccess = createMockResult(MockRouter.emptyAcceptStatuses, statusCode: 200)
        XCTAssertNoThrow(try testSuccess.get())
    }

    func testNotInAcceptableStatuses() {
        // error when status code not in acceptable statuses
        let testNotFound = createMockResult(MockRouter.regularAcceptStatuses, statusCode: 404)
        XCTAssertThrowsError(try testNotFound.get()) { error in
            var correctError = false
            if case NetworkError.unacceptableStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError)
        }

        // error when status code not in acceptable statuses
        let testSuccess = createMockResult(MockRouter.iregularAcceptStatuses, statusCode: 200)
        XCTAssertThrowsError(try testSuccess.get()) { error in
            var correctError = false
            if case NetworkError.unacceptableStatusCode = error {
                correctError = true
            }
            XCTAssert(correctError)
        }
    }

    func testNotHttpsURLResponse() {
        let mockEndpointRequest = EndpointRequest(MockRouter.regularAcceptStatuses)
        let mockURLRequest = URLRequest(url: MockRouter.regularAcceptStatuses.baseURL)

        let mockURLResponse = URLResponse(url: MockRouter.regularAcceptStatuses.baseURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let mockResponse = (Data(), mockURLResponse)
        let statusProcessor = StatusCodeProcessor()
        let mockResponsePublisher: AnyPublisher<Response, Error> = Just(mockResponse).setFailureType(to: Error.self).eraseToAnyPublisher()

        let testErrorNotStatusCodeResult = awaitCompletion(for: statusProcessor.process(mockResponsePublisher, with: mockURLRequest, for: mockEndpointRequest))

        XCTAssertThrowsError(try testErrorNotStatusCodeResult.get()) { error in
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
    func createMockResult(_ router: MockRouter, statusCode: HTTPStatusCode) -> Result<[Response], Error> {
        let mockEndpointRequest = EndpointRequest(router)
        let mockURLRequest = URLRequest(url: router.baseURL)
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: router.baseURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)

        let statusProcessor = StatusCodeProcessor()
        let mockResponsePublisher: AnyPublisher<Response, Error> = Just(mockResponse).setFailureType(to: Error.self).eraseToAnyPublisher()

        return awaitCompletion(for: statusProcessor.process(mockResponsePublisher, with: mockURLRequest, for: mockEndpointRequest))
    }
}
