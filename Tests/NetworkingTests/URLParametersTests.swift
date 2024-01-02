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
    enum Router: Requestable {
        case urlParameters([String : Any])

        var baseURL: URL {
            URL(string: baseURLString)!
        }

        var path: String {
            ""
        }

        var urlParameters: [String : Any]? {
            switch self {
            case let .urlParameters(parameters):
                parameters
            }
        }
    }

    func testParameterDefaultEncoding() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let router = Router.urlParameters(["date": dateString])
        let request = try router.asRequest()

        XCTAssertEqual(
            request.url?.absoluteString,
            "\(baseURLString)?date=\(dateString)"
        )
    }

    func testPlusSignPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let plusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let router = Router.urlParameters(["date": PercentEncodedParameter(dateString, percentEncoding: .plusSign)])
        let request = try router.asRequest()

        XCTAssertEqual(
            request.url?.absoluteString,
            "\(baseURLString)?date=\(plusSignPercentEncodedString)"
        )
    }
    
    func testMixedPlusSignPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let plusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let searchString = "name+surname"
        
        let router = Router.urlParameters([
                "date": PercentEncodedParameter(dateString, percentEncoding: .custom),
                "search": searchString
            ])
        let request = try router.asRequest()
        
        XCTAssertEqual(
            request.url?.absoluteString,
            "\(baseURLString)?date=\(plusSignPercentEncodedString)&search=\(searchString)"
        )
    }
    
    func testCustomPercentEncodedParameter() async throws {
        let customPercentEncodedString = "2023-11-29T12:13:04.598%2B+%0100"
        let router = Router.urlParameters(["date": PercentEncodedParameter(customPercentEncodedString, percentEncoding: .plusSign)])
        let request = try router.asRequest()

        XCTAssertEqual(
            request.url?.absoluteString,
            "\(baseURLString)?date=\(customPercentEncodedString)"
        )
    }
}
