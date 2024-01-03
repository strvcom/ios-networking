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

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "date"})?.value,
            dateString
        )
    }

    func testPlusSignPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let datePlusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let router = Router.urlParameters(["date": PercentEncodedParameter(dateString, percentEncoding: .plusSign)])
        let request = try router.asRequest()

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "date"})?.value,
            datePlusSignPercentEncodedString
        )
    }
    
    func testMixedPlusSignPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let datePlusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let searchString = "name+surname"
        
        let router = Router.urlParameters([
                "date": PercentEncodedParameter(dateString, percentEncoding: .custom),
                "search": searchString
            ])
        let request = try router.asRequest()
        
        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "date"})?.value,
            datePlusSignPercentEncodedString
        )
        
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "search"})?.value,
            searchString
        )
    }
    
    func testMixedPercentEncodedParameter() async throws {
        let dateString = "2023-11-29T12:13:04.598+0100"
        let datePlusSignPercentEncodedString = "2023-11-29T12:13:04.598%2B0100"
        let searchString = "name+surnam]e"
        let searchPercentEncodedString = "name+surnam%5De"
        
        let router = Router.urlParameters([
                "date": PercentEncodedParameter(dateString, percentEncoding: .plusSign),
                "search": searchString
            ])
        let request = try router.asRequest()
        
        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "date"})?.value,
            datePlusSignPercentEncodedString
        )
        
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "search"})?.value,
            searchPercentEncodedString
        )
    }
    
    func testCustomPercentEncodedParameter() async throws {
        let customPercentEncodedString = "2023-11-29T12:13:04.598%2B+%0100"
        let router = Router.urlParameters(["date": PercentEncodedParameter(customPercentEncodedString, percentEncoding: .custom)])
        let request = try router.asRequest()

        guard let url = request.url else {
            XCTFail("Can't create url from router")
            return
        }
        
        let queryItems = percentEncodedQueryItems(from: url)
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "date"})?.value,
            customPercentEncodedString
        )
    }
}

private extension URLParametersTests {
    // Helper method to create query items from URL to compare it with expected percent encoding
    func percentEncodedQueryItems(from: URL) -> [URLQueryItem] {
        let urlComponents = URLComponents(url: from, resolvingAgainstBaseURL: true)
        return urlComponents?.percentEncodedQueryItems ?? []
    }
}
