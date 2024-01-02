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

    func testISODateParameterDefaultEncoding() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let router = Router.urlParameters(["date": dateString])
        let request = try router.asRequest()

        XCTAssertEqual(
            request.url?.absoluteString,
            "\(baseURLString)?date=\(dateString)"
        )
    }

    func testISODateParameterIncorrectEncoding() async throws {
        let dateString = "2023-11-29T12:13:04.598%2B0100"
        let router = Router.urlParameters(["date": dateString])
        let request = try router.asRequest()

        XCTAssertNotEqual(
            request.url?.absoluteString,
            "\(baseURLString)?date=\(dateString)"
        )
    }

    func testISODatePercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598%2B0100"
        let router = Router.urlParameters(["date": PercentEncodedParameter(dateString)])
        let request = try router.asRequest()

        XCTAssertEqual(
            request.url?.absoluteString,
            "\(baseURLString)?date=\(dateString)"
        )
    }
}
