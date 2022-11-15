import XCTest

import NetworkingTests

var tests = [XCTestCaseEntry]()
tests += EndpointIdentifiableTests.allTests()
XCTMain(tests)
