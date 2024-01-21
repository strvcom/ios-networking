//
//  MockResponseProviderTests.swift
//
//
//  Created by Matej Molnár on 05.01.2023.
//

@testable import Networking
import XCTest

final class MockResponseProviderTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private lazy var mockUrlRequest = URLRequest(url: URL(string: "https://reqres.in/api/users?page=2")!)
    private let mockSessionId = "2023-01-04T16:15:29Z"
    
    private let mockHeaderFields = [
        "Server": "cloudflare",
        "Etag": "W/\"406-ut0vzoCuidvyMf8arZpMpJ6ZRDw\"",
        "x-powered-by": "Express",
        "nel": "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}",
        "Content-Encoding": "br",
        "Vary": "Accept-Encoding",
        // swiftlint:disable:next line_length
        "report-to": "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=5XGHUrnfYDsl7guBAx0nFk7LTbUgOLjp5%2BGMkSPetC5OrW6fKlUc1NBBtOKHKe9yWrcbXkF4TQe8jsv1c4KggYW1q4pYf5G2rQvA8XACg1znl6MbWiNj1w2wOg%3D%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}",
        "Content-Type": "application/json; charset=utf-8",
        "cf-cache-status": "HIT",
        "Cache-Control": "max-age=14400",
        "Access-Control-Allow-Origin": "*",
        "cf-ray": "784545f34d2f27bc-PRG",
        "Date": "Wed, 04 Jan 2023 16:15:29 GMT",
        "Via": "1.1 vegur",
        "Age": "6306"
    ]
    
    func testLoadingData() async throws {
        let mockResponseProvider = MockResponseProvider(with: Bundle.module, sessionId: mockSessionId)
        
        // call request multiple times, 6 testing data files
        // test reading correct file
        for index in 0...10 {
            let response = try await mockResponseProvider.response(for: mockUrlRequest)

            XCTAssert(response.response is HTTPURLResponse)

            guard let httpResponse = response.response as? HTTPURLResponse else {
                XCTAssert(false, "Wrong response type")
                return
            }
            
            guard let headerFields = httpResponse.allHeaderFields as? [String: String] else {
                XCTAssert(false, "Wrong response header fields type")
                return
            }
             
            XCTAssertEqual(headerFields, mockHeaderFields)
            
            switch index {
            case 3:
                XCTAssertEqual(httpResponse.statusCode, 200)
                XCTAssertEqual(response.data.count, 0)
            case 4:
                XCTAssertEqual(httpResponse.statusCode, 400)
                XCTAssertEqual(response.data.count, 0)
            default:
                XCTAssertEqual(httpResponse.statusCode, 200)
                XCTAssertEqual(response.data.count, 1030)
            }
        }
    }
    
    func testUnableToLoadAssetError() async {
        let mockResponseProvider = MockResponseProvider(with: Bundle.module, sessionId: "NonexistentSessionId")
        
        do {
            _ = try await mockResponseProvider.response(for: mockUrlRequest)
            XCTAssert(false, "function didn't throw an error even though it should have")
        } catch {
            var correctError = false
            if case NetworkError.underlying(error: MockResponseProviderError.unableToLoadAssetData) = error {
                correctError = true
            }
            XCTAssert(correctError, "function threw an incorrect error")
        }
    }
    
    func testUnableToConstructResponseError() async {
        let mockResponseProvider = MockResponseProvider(with: Bundle.module, sessionId: "2023-01-04T16:15:29Z(corrupted)")
        
        do {
            _ = try await mockResponseProvider.response(for: mockUrlRequest)
            XCTAssert(false, "function didn't throw an error even though it should have")
        } catch {
            var correctError = false
            if case NetworkError.underlying(error: MockResponseProviderError.unableToConstructResponse) = error {
                correctError = true
            }
            XCTAssert(correctError, "function threw an incorrect error")
        }
    }
    
    static var allTests = [
        ("testLoadingData", testLoadingData)
    ]
}
