import Combine
@testable import Networking
import XCTest

final class SampleDataNetworkingTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private lazy var urlRequest = URLRequest(url: URL(string: "https://reqres.in/api/users?page=2")!)
    private let sessionId = "04162021_103805AM"

    func testLoadingData() {
        let sampleDataNetworking = SampleDataNetworking(with: Bundle.module, sessionId: sessionId)

        // call request multiple times, 5 testing data files
        // test reading correct file
        for index in 1...10 {
            let result = awaitCompletion(for: sampleDataNetworking.requestPublisher(for: urlRequest))
            XCTAssertNoThrow(try result.get())

            if let response = try? result.get().first {
                XCTAssert(response.response is HTTPURLResponse)

                if let httpResponse = response.response as? HTTPURLResponse {
                    switch index {
                    case 3:
                        XCTAssertEqual(httpResponse.statusCode, 200)
                        XCTAssertEqual(response.data.count, 0)
                    case 4:
                        XCTAssertEqual(httpResponse.statusCode, 400)
                        XCTAssertEqual(response.data.count, 0)
                    default:
                        XCTAssertEqual(httpResponse.statusCode, 200)
                        XCTAssertEqual(response.data.count, 1030)
                    }
                }
            }
        }
    }

    static var allTests = [
        ("testLoadingData", testLoadingData)
    ]
}
