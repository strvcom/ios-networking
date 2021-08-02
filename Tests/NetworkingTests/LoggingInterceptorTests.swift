import Combine
@testable import Networking
import XCTest

final class LoggingInterceptorTests: XCTestCase {
    enum MockRouter: Requestable {
        case logging

        var baseURL: URL {
            // swiftlint:disable:next force_unwrapping
            URL(string: "https://loggingInterceptor.tests")!
        }

        var path: String {
            switch self {
            case .logging:
                return "logging"
            }
        }
    }

    func testNoEffect() {
        // test logging interceptor doesn't effect request or response anyway

        let mockEndpointRequest = EndpointRequest(MockRouter.logging)
        let mockURLRequest = URLRequest(url: MockRouter.logging.baseURL)
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: MockRouter.logging.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)
        let mockURLPublisher = Just(mockURLRequest).setFailureType(to: Error.self).eraseToAnyPublisher()
        let mockResponsePublisher: AnyPublisher<Response, Error> = Just(mockResponse).setFailureType(to: Error.self).eraseToAnyPublisher()

        let loggingInterceptor = LoggingInterceptor()
        let adaptResult = awaitCompletion(for: loggingInterceptor.adapt(mockURLPublisher, for: mockEndpointRequest))

        XCTAssertNoThrow(try adaptResult.get())
        if let urlRequest = try? adaptResult.get().first {
            XCTAssert(urlRequest == mockURLRequest)
        }

        let processResult = awaitCompletion(for: loggingInterceptor.process(mockResponsePublisher, with: mockURLRequest, for: mockEndpointRequest))
        XCTAssertNoThrow(try processResult.get())
        if let response = try? processResult.get().first {
            XCTAssert(response.data == mockResponse.0 && response.response == mockResponse.1)
        }
    }

    static var allTests = [
        ("testNoEffect", testNoEffect)
    ]
}
