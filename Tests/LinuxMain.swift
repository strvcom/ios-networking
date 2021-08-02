import XCTest

import NetworkingTests

var tests = [XCTestCaseEntry]()
tests += APIManagerTests.allTests()
tests += AuthenticationTokenInterceptorTests.allTests()
tests += EndpointIdentifiableTests.allTests()
tests += EndpointRequestStorageProcessorTests.allTests()
tests += LoggingInterceptorTests.allTests()
tests += RequestRetrierTests.allTests()
tests += SampleDataNetworkingTests.allTests()
tests += StatusCodeProcessorTests.allTests()
XCTMain(tests)
