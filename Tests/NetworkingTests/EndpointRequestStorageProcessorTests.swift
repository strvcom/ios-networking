import Combine
@testable import Networking
import XCTest

// MARK: -  Test Endpoint request storage processor

final class EndpointRequestStorageProcessorTests: XCTestCase {
    private let sessionId = "sessionId_request_storage"

    enum MockRouter: Requestable {
        case storing

        var baseURL: URL {
            // swiftlint:disable:next force_unwrapping
            URL(string: "https://endpointRequestStorageProcessor.tests")!
        }

        var path: String {
            switch self {
            case .storing:
                return "storing"
            }
        }
    }

    func testStoringData() {
        let mockEndpointRequest = EndpointRequest(MockRouter.storing, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: MockRouter.storing.baseURL)
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: MockRouter.storing.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)
        let mockResponsePublisher: AnyPublisher<Response, Error> = Just(mockResponse).setFailureType(to: Error.self).eraseToAnyPublisher()

        let storageProcessor = EndpointRequestStorageProcessor()
        let processResult = awaitCompletion(for: storageProcessor.process(mockResponsePublisher, with: mockURLRequest, for: mockEndpointRequest))

        // test storing data processor doesn't effect response anyway
        XCTAssertNoThrow(try processResult.get())
        if let response = try? processResult.get().first {
            XCTAssert(response.data == mockResponse.0 && response.response == mockResponse.1)
        }
    }

    static var allTests = [
        ("testStoringData", testStoringData)
    ]
}
