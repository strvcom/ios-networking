//
//  File.swift
//  
//
//  Created by Dominika Gajdová on 05.12.2022.
//

@testable import Networking
import XCTest
import Foundation

final class ErrorProcessorTests: XCTestCase {
    // Our mocked error processors don't utilise the endpointRequest parameter so we can use the same mocked endpointRequest for all tests
    private let mockEndpointRequest = EndpointRequest(MockRouter.sample, sessionId: "sessionId_error_process")
    
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
        let resultError = processor.process(notFoundError, for: mockEndpointRequest)
        
        if case MockSimpleError.simpleError(let statusCode) = resultError {
            XCTAssertEqual(statusCode, 404, "Expected status code 404 but received \(statusCode) instead.")
        } else {
            XCTFail("❌ Mapping to SimpleError failed.")
        }
    }
    
    func test_errorProcessing_process_mappingUnacceptableToUnrelatedThroughSimpleShouldSucceed() async {
        let processors: [ErrorProcessing] = [MockSimpleErrorProcessor(), MockUnrelatedErrorProcessor()]
        let mockResponse = createMockResponseParams(url: testUrl, statusCode: 404)
        let notFoundError = NetworkError.unacceptableStatusCode(
            statusCode: 404,
            acceptedStatusCodes: 200..<300,
            response: mockResponse
        )
        let resultError = await processors.process(notFoundError, for: mockEndpointRequest)
        
        if case MockUnrelatedError.unrelatedError(let message) = resultError {
            XCTAssertEqual(message, "Failed with statusCode: 404", "Expected a different error message.")
        } else {
            XCTFail("❌ Mapping to UnrelatedError failed.")
        }
    }
    
    func test_errorProcessing_process_undefinedCaseShouldReturnOriginalError() {
        let processor = MockSimpleErrorProcessor()
        let totallyUnrelated = MockUnrelatedError.totallyUnrelated
        let resultError = processor.process(totallyUnrelated, for: mockEndpointRequest)

        guard case MockUnrelatedError.totallyUnrelated = resultError else {
            XCTFail("❌ Mapping to SimpleError should fail.")
            return
        }
    }
    
    func test_errorProcessing_process_noProcessorsShouldReturnOriginalError() async {
        let processors: [ErrorProcessing] = []
        let invalidHeaderError = NetworkError.headerIsInvalid
        let resultError = await processors.process(invalidHeaderError, for: mockEndpointRequest)
        
        guard case NetworkError.headerIsInvalid = resultError else {
            XCTFail("❌ No mappings should have occured, but they did!.")
            return
        }
    }
    
    static var allTests = [
        ("test_errorProcessing_process_mappingUnacceptableToSimpleErrorShouldSucceed", test_errorProcessing_process_mappingUnacceptableToSimpleErrorShouldSucceed),
        ("test_errorProcessing_process_mappingUnacceptableToUnrelatedThroughSimpleShouldSucceed", test_errorProcessing_process_mappingUnacceptableToUnrelatedThroughSimpleShouldSucceed),
        ("test_errorProcessing_process_undefinedCaseShouldReturnOriginalError",
         test_errorProcessing_process_undefinedCaseShouldReturnOriginalError),
        ("test_apiManager_request_errorShouldBeMappedToSimpleError",
         test_apiManager_request_errorShouldBeMappedToSimpleError),
        ("test_apiManager_request_originalErrorShouldRemain",
         test_apiManager_request_originalErrorShouldRemain)
    ]
}

// MARK: Api Manager Integration test
extension ErrorProcessorTests {
    enum MockRouter: Requestable {
        case notFoundRequest
        case networkError
        case sample
        
        var baseURL: URL {
            switch self {
            case .notFoundRequest:
                // swiftlint:disable:next force_unwrapping
                return URL(string: "https://reqres.in/api")!
            case .networkError:
                // swiftlint:disable:next force_unwrapping
                return URL(string: "https://nonexistenturladdress")!
            case .sample:
                // swiftlint:disable:next force_unwrapping
                return URL(string: "https://sample.com")!
            }
        }

        var path: String { "/users/0" }
        var acceptableStatusCodes: Range<HTTPStatusCode>? { 200..<300 }
    }
    
    func test_apiManager_request_errorShouldBeMappedToSimpleError() async {
        let apiManager = APIManager(
            urlSession: URLSession.shared,
            errorProcessors: [MockSimpleErrorProcessor()]
        )
        
        do {
            try await apiManager.request(MockRouter.notFoundRequest)
            XCTFail("Expected to receive a network error but succeeded instead.")
        } catch MockSimpleError.simpleError {
            // Expected
        } catch {
            XCTFail("Expected to receive error of type MockSimpleError.")
        }
    }
    
    func test_apiManager_request_originalErrorShouldRemain() async {
        let apiManager = APIManager(
            urlSession: URLSession.shared,
            errorProcessors: [MockSimpleErrorProcessor()]
        )
        
        do {
            try await apiManager.request(MockRouter.networkError)
            XCTFail("Expected to receive a network error but succeeded instead.")
        } catch MockSimpleError.simpleError {
            XCTFail("Expected to receive error of type URLError.")
        } catch is URLError {
            // Expected
        } catch {
            XCTFail("Expected to receive error of type URLError.")
        }
    }
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
        func process(_ error: Error, for endpointRequest: EndpointRequest) -> Error {
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
        func process(_ error: Error, for endpointRequest: EndpointRequest) -> Error {
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
