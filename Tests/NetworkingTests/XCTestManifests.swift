import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(EndpointIdentifiableTests.allTests)
        ]
    }
#endif
