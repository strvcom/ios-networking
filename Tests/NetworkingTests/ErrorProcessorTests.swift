//
//  File.swift
//  
//
//  Created by Dominika Gajdová on 05.12.2022.
//

@testable import Networking
import XCTest

final class ErrorProcessorTests: XCTestCase {
    private let sessionId = "sessionId_error_process"
    
    // swiftlint:disable:next force_unwrapping
    private var testUrl: URL {
        URL(string: "http://sometesturl.com")!
    }
    
    func test_errorProcessing_process_mappingToSingleSimpleErrorShouldSucceed() {
        let processor = MockSimpleErrorProcessor()
                
        let mockResponse = createMockResponseParams(url: testUrl, statusCode: 404)
        let notFoundError = NetworkError.unacceptableStatusCode(
            statusCode: 404,
            acceptedStatusCodes: 200..<300,
            response: mockResponse
        )
        
        let resultError = processor.process(error: notFoundError)
        
        if case MockSimpleError.simpleError(let statusCode) = resultError {
            XCTAssertEqual(statusCode, 404)
        } else {
            XCTFail("❌ Mapping to SimpleError failed.")
        }
    }
    
    func test_errorProcessing_process_mappingThroughMultipleShouldSucceed() {
        let processors: [ErrorProcessing] = [MockSimpleErrorProcessor(), MockUnrelatedErrorProcessor()]
        
        let mockResponse = createMockResponseParams(url: testUrl, statusCode: 404)
        let notFoundError = NetworkError.unacceptableStatusCode(
            statusCode: 404,
            acceptedStatusCodes: 200..<300,
            response: mockResponse
        )
        
        let resultError = processors.process(notFoundError)
        
        if case MockUnrelatedError.unrelatedError(let message) = resultError {            
            XCTAssertEqual(message, "Failed with statusCode: 404")
        } else {
            XCTFail("❌ Mapping to UnrelatedError failed.")
        }
    }
}

// MARK: Custom Error Processors
private extension ErrorProcessorTests {
    enum MockSimpleError: Error {
        case simpleError(statusCode: Int)
    }
    
    enum MockUnrelatedError: Error {
        case unrelatedError(message: String)
    }
    
    // Maps NetworkError to SimpleError
    struct MockSimpleErrorProcessor: ErrorProcessing {
        func process(error: Error) -> Error {
            if case NetworkError.unacceptableStatusCode(let statusCode, _, _) = error {
                return MockSimpleError.simpleError(statusCode: statusCode)
            }
            
            // ...
            // more cases for each NetworkError
            // ...
            
            // otherwise return unprocessed original error
            return error
        }
    }
    
    struct MockUnrelatedErrorProcessor: ErrorProcessing {
        func process(error: Error) -> Error {
            if case MockSimpleError.simpleError(let statusCode) = error {
                return MockUnrelatedError.unrelatedError(message: "Failed with statusCode: \(statusCode)")
            }
            
            // ...
            // more cases for each NetworkError
            // ...
            
            // otherwise return unprocessed original error
            return error
        }
    }
}

// MARK: - Factory methods to create mock objects
private extension ErrorProcessorTests {
    func createMockResponseParams(
        url: URL,
        statusCode: HTTPStatusCode
    ) -> Response {
        let mockURLRequest = URLRequest(url: url)
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)
        return mockResponse
    }
}
