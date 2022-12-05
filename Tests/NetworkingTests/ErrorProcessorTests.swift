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
    
    func test_errorProcessing_process_mappingUnacceptableToSimpleErrorShouldSucceed() {
        let processor = MockSimpleErrorProcessor()
        let mockResponse = createMockResponseParams(url: testUrl, statusCode: 404)
        let notFoundError = NetworkError.unacceptableStatusCode(
            statusCode: 404,
            acceptedStatusCodes: 200..<300,
            response: mockResponse
        )
        let resultError = processor.process(notFoundError)
        
        if case MockSimpleError.simpleError(let statusCode) = resultError {
            XCTAssertEqual(statusCode, 404)
        } else {
            XCTFail("❌ Mapping to SimpleError failed.")
        }
    }
    
    func test_errorProcessing_process_mappingUnacceptableToUnrelatedThroughSimpleShouldSucceed() {
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
    
    func test_errorProcessing_process_undefinedCaseShouldReturnOriginalError() {
        let processor = MockSimpleErrorProcessor()
        let totallyUnrelated = MockUnrelatedError.totallyUnrelated
        let resultError = processor.process(totallyUnrelated)

        if case MockUnrelatedError.totallyUnrelated = resultError {
            XCTAssert(true)
        } else {
            XCTFail("❌ Mapping to SimpleError should fail.")
        }
    }
    
    func test_errorProcessing_process_noProcessorsShouldReturnOriginalError() {
        let processors: [ErrorProcessing] = []
        let invalidHeaderError = NetworkError.headerIsInvalid
        let resultError = processors.process(invalidHeaderError)
        
        if case NetworkError.headerIsInvalid = resultError {
            XCTAssert(true)
        } else {
            XCTFail("❌ No mappings should have occured, but they did!.")
        }
    }
    
    static var allTests = [
        ("test_errorProcessing_process_mappingUnacceptableToSimpleErrorShouldSucceed", test_errorProcessing_process_mappingUnacceptableToSimpleErrorShouldSucceed),
        ("test_errorProcessing_process_mappingUnacceptableToUnrelatedThroughSimpleShouldSucceed", test_errorProcessing_process_mappingUnacceptableToUnrelatedThroughSimpleShouldSucceed),
        ("test_errorProcessing_process_undefinedCaseShouldReturnOriginalError", test_errorProcessing_process_undefinedCaseShouldReturnOriginalError),
    ]
}

// MARK: Mock Errors
private extension ErrorProcessorTests {
    enum MockSimpleError: Error {
        case simpleError(statusCode: Int)
        case notSoSimpleError(data: Data)
        case underlying(error: NetworkError)
    }
    
    enum MockUnrelatedError: Error {
        case unrelatedError(message: String)
        case totallyUnrelated
    }
}

// MARK: Custom Error Processors
private extension ErrorProcessorTests {
    // Maps NetworkError to SimpleError
    struct MockSimpleErrorProcessor: ErrorProcessing {
        func process(_ error: Error) -> Error {
            if case NetworkError.unacceptableStatusCode(let statusCode, _, _) = error {
                return MockSimpleError.simpleError(statusCode: statusCode)
            }
            
            if case NetworkError.noStatusCode(let response) = error {
                return MockSimpleError.notSoSimpleError(data: response.data)
            }

            if let error = error as? NetworkError {
                return MockSimpleError.underlying(error: error)
            }
            
            return error
        }
    }
    
    struct MockUnrelatedErrorProcessor: ErrorProcessing {
        func process(_ error: Error) -> Error {
            if case MockSimpleError.simpleError(let statusCode) = error {
                return MockUnrelatedError.unrelatedError(message: "Failed with statusCode: \(statusCode)")
            }
            
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
        // swiftlint:disable:next force_unwrapping
        let mockURLResponse: URLResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)
        return mockResponse
    }
}
