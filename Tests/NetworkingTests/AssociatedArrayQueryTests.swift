//
//  File.swift
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
        
        var baseURL: URL { URL(string: "http://someurl.com")! }
        var path: String { "" }
        
        var urlParameters: [String: Any]? {
            switch self {
            case .single:
                return ["filter": 1]
                
            case .arrayIndividual:
                return ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .individual)]
                
            case .arraySeparated:
                return ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .commaSeparated)]
                
            case .both:
                return ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .individual), "data": 5]
            }
        }
    }
    
    func testMultipleKeyParamaterURLCreation() async throws {
        let urlRequest1 = try TestRouter.single.asRequest()
        XCTAssertEqual("http://someurl.com/?filter=1", urlRequest1.url?.absoluteString ?? "")
        
        let urlRequest2 = try TestRouter.arrayIndividual.asRequest()
        XCTAssertEqual("http://someurl.com/?filter=1&filter=2&filter=3", urlRequest2.url?.absoluteString ?? "")

        let urlRequest3 = try TestRouter.arraySeparated.asRequest()
        XCTAssertEqual("http://someurl.com/?filter=1,2,3", urlRequest3.url?.absoluteString ?? "")
        
        let urlRequest4 = try TestRouter.both.asRequest()
        
        if let url = urlRequest4.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems,
           let parameters = TestRouter.both.urlParameters
        {
            let result = parameters.allSatisfy { (key, value) in
                queryItems.contains(where: { $0.name == key })
            }
            
            XCTAssertTrue(result)
        } else {
            XCTFail("Invalid request url and/or query parameters.")
        }
    }
}
