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
        
        var baseURL: URL { URL(string: "http://someurl.com")! }
        var path: String { "" }
        
        var urlParameters: [String: Any]? {
            switch self {
            case .single:
                return ["filter": 1]
                
            case .arrayIndividual:
                return ["filter": ArrayType([1, 2, 3],arrayEncoding: .individual), "drama": 0]
                
            case .arraySeparated:
                return ["filter": ArrayType([1, 2, 3],arrayEncoding: .commaSeparated)]
            }
        }
    }
    
    func testMultipleKeyParamaterURLCreation() async throws {
        let urlRequest1 = try TestRouter.single.asRequest()
        XCTAssertEqual("http://someurl.com/?filter=1", urlRequest1.url?.absoluteString ?? "")
        
        let urlRequest2 = try TestRouter.arrayIndividual.asRequest()
        XCTAssertEqual("http://someurl.com/?drama=0&filter=1&filter=2&filter=3", urlRequest2.url?.absoluteString ?? "")

        let urlRequest3 = try TestRouter.arraySeparated.asRequest()
        XCTAssertEqual("http://someurl.com/?filter=1,2,3", urlRequest3.url?.absoluteString ?? "")
    }
}
