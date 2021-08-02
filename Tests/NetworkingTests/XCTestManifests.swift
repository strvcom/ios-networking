import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(APIManagerTests.allTests),
            testCase(AuthenticationTokenInterceptorTests.allTests),
            testCase(EndpointIdentifiableTests.allTests),
            testCase(EndpointRequestStorageProcessorTests.allTests),
            testCase(LoggingInterceptorTests.allTests),
            testCase(RequestRetrierTests.allTests),
            testCase(SampleDataNetworkingTests.allTests),
            testCase(StatusCodeProcessorTests.allTests)
        ]
    }
#endif
