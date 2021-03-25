import XCTest
@testable import ios_networking

final class ios_networkingTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ios_networking().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
