//
//  EndpointIdentifiableTests.swift
//
//
//  Created by Tomas Cejka on 15.04.2021.
//

import Foundation
@testable import Networking
import XCTest

final class EndpointIdentifiableTests: XCTestCase {
    enum MockRouter: Requestable {
        case testPlain
        case testMethod
        case testParameters

        var baseURL: URL {
            // swiftlint:disable:next force_unwrapping
            URL(string: "https://identifiable.tests")!
        }

        var path: String {
            switch self {
            case .testPlain:
                return "testPlain"
            case .testMethod:
                return "testMethod"
            case .testParameters:
                return "testParameters"
            }
        }

        var urlParameters: [String: Any]? {
            switch self {
            case .testParameters:
                return [
                    "page": 1,
                    "limit": 20,
                    "empty": "",
                    "string": "!test!",
                    "alphabetically": true
                ]
            default:
                return nil
            }
        }

        var method: HTTPMethod {
            switch self {
            case .testMethod:
                return .delete
            default:
                return .get
            }
        }

        var url: URL {
            switch self {
            case .testPlain:
                // swiftlint:disable:next force_unwrapping
                return URL(string: "https://identifiable.tests/testPlain")!
            case .testMethod:
                // swiftlint:disable:next force_unwrapping
                return URL(string: "https://identifiable.tests/testMethod")!
            case .testParameters:
                // swiftlint:disable:next force_unwrapping
                return URL(string: "https://identifiable.tests/testParameters?page=1&limit=20&empty=&string=!test!&alphabetically=true")!
            }
        }
    }

    func testEqualIdentifiers() {
        // test identifier for plain request
        var plainRequest = URLRequest(url: MockRouter.testPlain.url)
        XCTAssertEqual(MockRouter.testPlain.identifier, plainRequest.identifier)

        // url creation from requestable
        XCTAssertNoThrow(try MockRouter.testPlain.asRequest())
        let plainUrl = try? MockRouter.testPlain.asRequest()
        XCTAssertEqual(plainUrl?.url, plainRequest.url)

        // test identifier for different http method
        plainRequest.httpMethod = "POST"
        XCTAssertNotEqual(MockRouter.testPlain.identifier, plainRequest.identifier)

        // test identifier for same http method, other than GET
        var methodRequest = URLRequest(url: MockRouter.testMethod.url)
        methodRequest.httpMethod = "DELETE"
        XCTAssertEqual(MockRouter.testMethod.identifier, methodRequest.identifier)

        // url creation from requestable
        XCTAssertNoThrow(try MockRouter.testMethod.asRequest())
        let methodUrl = try? MockRouter.testMethod.asRequest()
        XCTAssertEqual(methodUrl?.url, methodRequest.url)

        // test identifier for different url with same method
        methodRequest.url = MockRouter.testPlain.url
        XCTAssertNotEqual(MockRouter.testMethod.identifier, methodRequest.identifier)

        // test identifier for request with parameters
        // for parameters we don't expect also same generated URLs
        let parametersRequest = URLRequest(url: MockRouter.testParameters.url)
        XCTAssertEqual(MockRouter.testParameters.identifier, parametersRequest.identifier)

        // url creation from requestable
        XCTAssertNoThrow(try MockRouter.testParameters.asRequest())
    }

    static var allTests = [
        ("testEqualIdentifiers", testEqualIdentifiers)
    ]
}

// https://identifiable.tests/testParameters?alphabetically=true&string=!test!&page=1&limit=20&empty=
// https://identifiable.tests/testParameters?page=1&limit=20&empty=&string=!test!&alphabetically=true
