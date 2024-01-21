//
//  AssociatedArrayQueryTests.swift
//
//
//  Created by Dominika Gajdová on 08.05.2023.
//

@testable import Networking
import XCTest

final class AssociatedArrayQueryTests: XCTestCase {
    enum TestRouter: Requestable {
        case single
        case arrayIndividual
        case arraySeparated
        case both
        
        var baseURL: URL {
            // swiftlint:disable:next force_unwrapping
            URL(string: "https://someurl.com/")!
        }
        
        var path: String { "" }
        
          var urlParameters: [String: Any]? {
            switch self {
            case .single:
                ["filter": 1]
                
            case .arrayIndividual:
                ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .individual)]
                
            case .arraySeparated:
                ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .commaSeparated)]
                
            case .both:
                ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .individual), "data": 5]
            }
        }
    }
    
    func testMultipleKeyParamaterURLCreation() async throws {
        let urlRequest1 = try TestRouter.single.asRequest()
        XCTAssertEqual("https://someurl.com/?filter=1", urlRequest1.url?.absoluteString ?? "")
        
        let urlRequest2 = try TestRouter.arrayIndividual.asRequest()
        XCTAssertEqual("https://someurl.com/?filter=1&filter=2&filter=3", urlRequest2.url?.absoluteString ?? "")

        let urlRequest3 = try TestRouter.arraySeparated.asRequest()
        XCTAssertEqual("https://someurl.com/?filter=1,2,3", urlRequest3.url?.absoluteString ?? "")
        
        let urlRequest4 = try TestRouter.both.asRequest()
        
        if let url = urlRequest4.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems,
           let parameters = TestRouter.both.urlParameters {
            let result = parameters.allSatisfy { (key, _) in
                queryItems.contains(where: { $0.name == key })
            }
            XCTAssertTrue(result)
        } else {
            XCTFail("Invalid request url and/or query parameters.")
        }
    }
}
