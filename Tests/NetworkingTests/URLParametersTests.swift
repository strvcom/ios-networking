//
//  URLParametersTests.swift
//
//
//  Created by Matej Molnár on 02.01.2024.
//

import Networking
import XCTest

private let baseURLString = "https://requestable.tests"

final class URLParametersTests: XCTestCase {
    func testDefaultEncoding() async throws {
        let keyString = "name[first]"
        let keyPercentEncodedString = "name%5Bfirst%5D"
        let valueString = "name]surname"
        let valuePercentEncodedString = "name%5Dsurname"

        let router = Router.urlParameters([keyString: valueString])
        let request = try router.asRequest()
        
        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        
        XCTAssertEqual(
            queryItems.value(for: keyPercentEncodedString),
            valuePercentEncodedString
        )
    }

    func testPlusSignDefaultEncoding() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let router = Router.urlParameters(["date": dateString])
        let request = try router.asRequest()

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.value(for: "date"),
            dateString
        )
    }

    func testPlusSignPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let datePlusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let router = Router.urlParameters(["date": CustomEncodedParameter(dateString.plusSignEncoded() ?? "")])
        let request = try router.asRequest()

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.value(for: "date"),
            datePlusSignPercentEncodedString
        )
    }
    
    func testMixedPlusSignPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let datePlusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let searchString = "name+surname"
        
        let router = Router.urlParameters([
            "date": CustomEncodedParameter(dateString.plusSignEncoded() ?? ""),
                "search": searchString
            ])
        let request = try router.asRequest()
        
        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.value(for: "date"),
            datePlusSignPercentEncodedString
        )
        
        XCTAssertEqual(
            queryItems.value(for: "search"),
            searchString
        )
    }
    
    func testMixedPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let datePlusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let searchString = "name+surnam]e"
        let searchPercentEncodedString = "name+surnam%5De"
        
        let router = Router.urlParameters([
            "date": CustomEncodedParameter(dateString.plusSignEncoded() ?? ""),
                "search": searchString
            ])
        let request = try router.asRequest()
        
        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.value(for: "date"),
            datePlusSignPercentEncodedString
        )
        
        XCTAssertEqual(
            queryItems.value(for: "search"),
            searchPercentEncodedString
        )
    }
    
    func testCustomPercentEncodedParameter() async throws {
        let customPercentEncodedString = "2023-11-29T12:13:04.598%2B+%0100"
        let router = Router.urlParameters([
            "date": CustomEncodedParameter(customPercentEncodedString)
        ])
        let request = try router.asRequest()

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.value(for: "date"),
            customPercentEncodedString
        )
    }

    func testOptionalsParametersEncodingWithValues() async throws {
        let parameters = OptionalParameters(
            int: 10,
            string: "testString",
            stringsArray: ["1", "2"]
        )
        let router = OptionalParametersRouter.test(parameters)

        let request = try router.asRequest()

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }

        let queryItems = percentEncodedQueryItems(from: url)

        XCTAssertEqual(
            queryItems.value(for: OptionalParameters.CodingKeys.int.stringValue),
            "10"
        )
        XCTAssertEqual(
            queryItems.value(for: OptionalParameters.CodingKeys.string.stringValue),
            "testString"
        )
        XCTAssertEqual(
            queryItems.value(for: OptionalParameters.CodingKeys.stringsArray.stringValue),
            "1,2"
        )
    }

    func testOptionalsParametersEncodingWithNils() async throws {
        let parameters = OptionalParameters(
            int: 10,
            string: nil,
            stringsArray: nil
        )
        let router = OptionalParametersRouter.test(parameters)

        let request = try router.asRequest()

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }

        let queryItems = percentEncodedQueryItems(from: url)

        XCTAssertEqual(
            queryItems.value(for: OptionalParameters.CodingKeys.int.stringValue),
            "10"
        )
        XCTAssertEqual(
            queryItems.value(for: OptionalParameters.CodingKeys.string.stringValue),
            nil
        )
        XCTAssertEqual(
            queryItems.value(for: OptionalParameters.CodingKeys.stringsArray.stringValue),
            nil
        )
    }
}

// MARK: Helpers
private extension URLParametersTests {
    // Helper method to create query items from URL to compare it with expected percent encoding
    func percentEncodedQueryItems(from: URL) -> [URLQueryItem] {
        let urlComponents = URLComponents(url: from, resolvingAgainstBaseURL: true)
        return urlComponents?.percentEncodedQueryItems ?? []
    }
}

private extension [URLQueryItem] {
    func value(for key: String) -> String? {
        first(where: { $0.name == key })?.value
    }
}

// MARK: Routers
private enum Router: Requestable {
    case urlParameters([String: any Sendable])

    var baseURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: baseURLString)!
    }

    var path: String {
        ""
    }

    var urlParameters: [String: Any]? {
        switch self {
        case let .urlParameters(parameters):
            parameters
                .compactMapValues { $0 }
        }
    }
}

private struct OptionalParameters: Codable {
    enum CodingKeys: CodingKey {
        case int
        case string
        case stringsArray
    }

    let int: Int?
    let string: String?
    let stringsArray: [String]?
}

private enum OptionalParametersRouter: Requestable {
    case test(OptionalParameters)

    var baseURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: baseURLString)!
    }

    var path: String {
        ""
    }

    var urlParameters: [String: Any]? {
        switch self {
        case let .test(params):
            var urlParameters: [String: Any] = [
                OptionalParameters.CodingKeys.int.stringValue: params.int as Any,
                OptionalParameters.CodingKeys.string.stringValue: params.string as Any
            ]

            if let stringsArray = params.stringsArray {
                urlParameters[OptionalParameters.CodingKeys.stringsArray.stringValue] = ArrayParameter(stringsArray, arrayEncoding: .commaSeparated)
            }

            return urlParameters
        }
    }

    var method: HTTPMethod {
        .get
    }
}
