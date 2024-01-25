//
//  EndpointRequestStorageProcessorTests.swift
//
//
//  Created by Matej Molnár on 12.12.2022.
//

@testable import Networking
import XCTest

// swiftlint:disable force_unwrapping

// MARK: - Test Endpoint request storage processor

final class EndpointRequestStorageProcessorTests: XCTestCase {
    private let sessionId = "sessionId_request_storage"
    private let fileManager = MockFileManager()

    struct MockBody: Codable {
        let parameter: String
    }
    
    enum MockRouter: Requestable {
        case testStoringGet
        case testStoringPost
        case testStoringImage
        case testStoringError
        
        var baseURL: URL {
            URL(string: "https://endpointRequestStorageProcessor.tests")!
        }

        var path: String {
            switch self {
            case .testStoringGet:
                "storing"
            case .testStoringPost:
                "storing"
            case .testStoringImage:
                "image"
            case .testStoringError:
                "error"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .testStoringGet, .testStoringImage, .testStoringError:
                .get
            case .testStoringPost:
                .post
            }
        }
        var urlParameters: [String: Any]? {
            switch self {
            case .testStoringGet, .testStoringPost, .testStoringImage, .testStoringError:
                ["query": "mock"]
            }
        }
        
        var headers: [String: String]? {
            switch self {
            case .testStoringGet, .testStoringPost, .testStoringImage, .testStoringError:
                ["mockRequestHeader": "mock"]
            }
        }
        
        var dataType: RequestDataType? {
            switch self {
            case .testStoringGet, .testStoringImage, .testStoringError:
                nil
            case .testStoringPost:
                .encodable(MockBody(parameter: "mock"))
            }
        }
    }

    override func tearDown() {
        fileManager.reset()

        super.tearDown()
    }

    func testResponseStaysTheSameAfterStoringData() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.testStoringGet, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: MockRouter.testStoringGet.baseURL)
        let mockURLResponse: URLResponse = HTTPURLResponse(url: MockRouter.testStoringGet.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)

        let response = try await EndpointRequestStorageProcessor().process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        // test storing data processor doesn't effect response in anyway
        XCTAssert(response.data == mockResponse.0 && response.response == mockResponse.1)
    }

    func testStoredDataForGetRequestWithJSONResponse() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.testStoringGet, sessionId: sessionId)
        let mockURLRequest = try mockEndpointRequest.endpoint.asRequest()
        let mockURLResponse: URLResponse = HTTPURLResponse(
            url: mockEndpointRequest.endpoint.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["mockResponseHeader": "mock"]
        )!
        let mockResponseData = "Mock data".data(using: .utf8)!
        let mockResponse = (mockResponseData, mockURLResponse)
        let expectation = expectation(description: "Data was written")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let fileDataWriterSpy = FileDataWriterSpy()
        fileDataWriterSpy.writeClosure = {
            expectation.fulfill()
        }

        let processor = EndpointRequestStorageProcessor(
            fileManager: fileManager,
            fileDataWriter: fileDataWriterSpy,
            jsonEncoder: encoder
        )
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 10)

        let fileUrl = fileUrl(for: mockEndpointRequest)

        guard let data = fileManager.contents(atPath: fileUrl.path) else {
            XCTAssert(false, "File doesn't exist")
            return
        }
        
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)

        XCTAssertEqual(model.statusCode, 200)
        XCTAssertEqual(model.method, "GET")
        XCTAssertEqual(model.path, mockEndpointRequest.endpoint.path)
        XCTAssertEqual(model.parameters, ["query": "mock"])
        XCTAssertNil(model.requestBody)
        XCTAssertNil(model.requestBodyString)
        XCTAssertEqual(model.requestHeaders, mockURLRequest.allHTTPHeaderFields)
        XCTAssertEqual(model.responseBody, mockResponseData)
        XCTAssertEqual(model.responseBodyString, String(data: mockResponseData, encoding: .utf8))
        XCTAssertEqual(model.responseHeaders, ["mockResponseHeader": "mock"])
    }
    
    func testStoredDataForGetRequestWithImageResponse() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.testStoringGet, sessionId: sessionId)
        let mockURLRequest = try mockEndpointRequest.endpoint.asRequest()
        let mockURLResponse: URLResponse = HTTPURLResponse(
            url: mockEndpointRequest.endpoint.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["mockResponseHeader": "mock"]
        )!
        
        #if os(macOS)
        let nsImage = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)!
        let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let mockResponseData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
        #else
        let mockResponseData = UIImage(systemName: "pencil")!.pngData()!
        #endif
        
        let mockResponse = (mockResponseData, mockURLResponse)
        let expectation = expectation(description: "Data was written")

        let fileDataWriterSpy = FileDataWriterSpy()
        fileDataWriterSpy.writeClosure = {
            expectation.fulfill()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(
            fileManager: fileManager,
            fileDataWriter: fileDataWriterSpy,
            jsonEncoder: encoder
        )
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 10)

        let fileUrl = fileUrl(for: mockEndpointRequest)

        guard let data = fileManager.contents(atPath: fileUrl.path) else {
            XCTAssert(false, "File doesn't exist")
            return
        }
        
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)

        XCTAssertEqual(model.statusCode, 200)
        XCTAssertEqual(model.method, "GET")
        XCTAssertEqual(model.path, mockEndpointRequest.endpoint.path)
        XCTAssertEqual(model.parameters, ["query": "mock"])
        XCTAssertNil(model.requestBody)
        XCTAssertNil(model.requestBodyString)
        XCTAssertEqual(model.requestHeaders, mockURLRequest.allHTTPHeaderFields)
        XCTAssertEqual(model.responseBody, mockResponseData)
        XCTAssertEqual(model.responseBodyString, String(data: mockResponseData, encoding: .utf8))
        XCTAssertEqual(model.responseHeaders, ["mockResponseHeader": "mock"])
    }
    
    func testStoredDataForGetRequestWithErrorResponse() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.testStoringError, sessionId: sessionId)
        let mockURLRequest = try mockEndpointRequest.endpoint.asRequest()
        let mockURLResponse: URLResponse = HTTPURLResponse(
            url: mockEndpointRequest.endpoint.baseURL,
            statusCode: 404,
            httpVersion: nil,
            headerFields: ["mockResponseHeader": "mock"]
        )!
        let mockResponseData = "Not found".data(using: .utf8)!
        let mockResponse = (mockResponseData, mockURLResponse)
        let mockError = NetworkError.unacceptableStatusCode(
            statusCode: 404,
            acceptedStatusCodes: HTTPStatusCode.successCodes,
            response: mockResponse
        )

        let expectation = expectation(description: "Data was written")

        let fileDataWriterSpy = FileDataWriterSpy()
        fileDataWriterSpy.writeClosure = {
            expectation.fulfill()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(
            fileManager: fileManager,
            fileDataWriter: fileDataWriterSpy,
            jsonEncoder: encoder
        )

        _ = await processor.process(mockError, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 10)

        let fileUrl = fileUrl(for: mockEndpointRequest)

        guard let data = fileManager.contents(atPath: fileUrl.path) else {
            XCTAssert(false, "File doesn't exist")
            return
        }
        
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)
        
        XCTAssertEqual(model.statusCode, 404)
        XCTAssertEqual(model.method, "GET")
        XCTAssertEqual(model.path, mockEndpointRequest.endpoint.path)
        XCTAssertEqual(model.parameters, ["query": "mock"])
        XCTAssertNil(model.requestBody)
        XCTAssertNil(model.requestBodyString)
        XCTAssertEqual(model.requestHeaders, mockURLRequest.allHTTPHeaderFields)
        XCTAssertEqual(model.responseBody, mockResponseData)
        XCTAssertEqual(model.responseBodyString, String(data: mockResponseData, encoding: .utf8))
        XCTAssertEqual(model.responseHeaders, ["mockResponseHeader": "mock"])
    }
    
    func testStoredDataForPostRequest() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.testStoringPost, sessionId: sessionId)
        let mockURLRequest = try mockEndpointRequest.endpoint.asRequest()
        let mockURLResponse: URLResponse = HTTPURLResponse(
            url: mockEndpointRequest.endpoint.baseURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["mockResponseHeader": "mock"]
        )!
        let mockResponseData = "Mock data".data(using: .utf8)!
        let mockResponse = (mockResponseData, mockURLResponse)

        let expectation = expectation(description: "Data was written")

        let fileDataWriterSpy = FileDataWriterSpy()
        fileDataWriterSpy.writeClosure = {
            expectation.fulfill()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(
            fileManager: fileManager,
            fileDataWriter: fileDataWriterSpy,
            jsonEncoder: encoder
        )
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 10)

        let fileUrl = fileUrl(for: mockEndpointRequest)

        guard let data = fileManager.contents(atPath: fileUrl.path) else {
            XCTAssert(false, "File doesn't exist")
            return
        }
                
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)
        let mockRequestBody = try mockEndpointRequest.endpoint.encodeBody()!

        XCTAssertEqual(model.statusCode, 200)
        XCTAssertEqual(model.method, "POST")
        XCTAssertEqual(model.path, mockEndpointRequest.endpoint.path)
        XCTAssertEqual(model.parameters, ["query": "mock"])
        XCTAssertEqual(model.requestBody, mockRequestBody)
        XCTAssertEqual(model.requestBodyString, String(data: mockRequestBody, encoding: .utf8))
        XCTAssertEqual(model.requestHeaders, mockURLRequest.allHTTPHeaderFields)
        XCTAssertEqual(model.responseBody, mockResponseData)
        XCTAssertEqual(model.responseBodyString, String(data: mockResponseData, encoding: .utf8))
        XCTAssertEqual(model.responseHeaders, ["mockResponseHeader": "mock"])
    }
    
    // swiftlint:enable force_unwrapping
    static var allTests = [
        ("testResponseStaysTheSameAfterStoringData", testResponseStaysTheSameAfterStoringData),
        ("testStoredDataForGetRequestWithJSONResponse", testStoredDataForGetRequestWithJSONResponse),
        ("testStoredDataForGetRequestWithImageResponse", testStoredDataForGetRequestWithImageResponse),
        ("testStoredDataForGetRequestWithErrorResponse", testStoredDataForGetRequestWithErrorResponse),
        ("testStoredDataForPostRequest", testStoredDataForPostRequest)
    ]
}

private extension EndpointRequestStorageProcessorTests {
    func fileUrl(for endpointRequest: EndpointRequest) -> URL {
        let responsesDirectory = fileManager.temporaryDirectory.appendingPathComponent("responses")
        let fileName = "\(endpointRequest.sessionId)_\(endpointRequest.endpoint.identifier)_0"
        return responsesDirectory
            .appendingPathComponent(endpointRequest.sessionId)
            .appendingPathComponent("\(fileName).json")
    }
}
