//
//  EndpointRequestStorageProcessorTests.swift
//  
//
//  Created by Matej Molnár on 12.12.2022.
//

@testable import Networking
import XCTest

// MARK: - Test Endpoint request storage processor

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

    func testResponseStaysTheSameAfterStoringData() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.storing, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: MockRouter.storing.baseURL)
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: MockRouter.storing.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)

        let response = try await EndpointRequestStorageProcessor().process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        // test storing data processor doesn't effect response in anyway
        XCTAssert(response.data == mockResponse.0 && response.response == mockResponse.1)
    }

    static var allTests = [
        ("testResponseStaysTheSameAfterStoringData", testResponseStaysTheSameAfterStoringData)
    ]
}
