import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(NetworkingTests.allTests)
        ]
    }
#endif
