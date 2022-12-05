import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(EndpointIdentifiableTests.allTests),
            testCase(StatusCodeProcessorTests.allTests),
            testCase(ErrorProcessorTests.allTests)
        ]
    }
#endif
