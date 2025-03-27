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

@NetworkingActor
final class EndpointRequestStorageProcessorTests: XCTestCase {
    private let sessionId = "sessionId_request_storage"
    private let mockFileManager = MockFileManager()

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
        mockFileManager.reset()

        super.tearDown()
    }

    func testResponseStaysTheSameAfterStoringData() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.testStoringGet, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: MockRouter.testStoringGet.baseURL)
        let mockURLResponse: URLResponse = HTTPURLResponse(url: MockRouter.testStoringGet.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)

        let response = try await EndpointRequestStorageProcessor().process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        // test storing data processor doesn't effect response in anyway
        XCTAssertEqual(response.data, mockResponse.0)
        XCTAssertEqual(response.response, mockResponse.1)
    }

    func testProcessCreatesCorrectFolder() async throws {
        let mockEndpointRequest = EndpointRequest(MockRouter.testStoringGet, sessionId: sessionId)
        let mockURLRequest = URLRequest(url: MockRouter.testStoringGet.baseURL)
        let mockURLResponse: URLResponse = HTTPURLResponse(url: MockRouter.testStoringGet.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mockResponse = (Data(), mockURLResponse)

        let expectation = expectation(description: "Data was written")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let mockFileDataWriter = MockFileDataWriter()
        mockFileDataWriter.writeClosure = {
            expectation.fulfill()
        }

        let processor = EndpointRequestStorageProcessor(
            fileManager: mockFileManager,
            fileDataWriter: mockFileDataWriter,
            jsonEncoder: encoder
        )
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 60)

        mockFileManager.verifyFunctionCall(.fileExists(path: responsesDirectory(for: mockEndpointRequest).path))
        mockFileManager.verifyFunctionCall(.createDirectory(path: responsesDirectory(for: mockEndpointRequest).path))

        XCTAssertEqual(mockFileDataWriter.receivedURL, fileUrl(for: mockEndpointRequest))
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
        let mockFileDataWriter = MockFileDataWriter()
        mockFileDataWriter.writeClosure = {
            expectation.fulfill()
        }

        let processor = EndpointRequestStorageProcessor(
            fileManager: mockFileManager,
            fileDataWriter: mockFileDataWriter,
            jsonEncoder: encoder
        )
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 60)

        let receivedData = try XCTUnwrap(mockFileDataWriter.receivedData)
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: receivedData)

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

        XCTAssertEqual(mockFileDataWriter.receivedURL, fileUrl(for: mockEndpointRequest))
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

        let mockFileDataWriter = MockFileDataWriter()
        mockFileDataWriter.writeClosure = {
            expectation.fulfill()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(
            fileManager: mockFileManager,
            fileDataWriter: mockFileDataWriter,
            jsonEncoder: encoder
        )
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 60)

        let receivedData = try XCTUnwrap(mockFileDataWriter.receivedData)
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: receivedData)

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

        XCTAssertEqual(mockFileDataWriter.receivedURL, fileUrl(for: mockEndpointRequest))
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

        let mockFileDataWriter = MockFileDataWriter()
        mockFileDataWriter.writeClosure = {
            expectation.fulfill()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(
            fileManager: mockFileManager,
            fileDataWriter: mockFileDataWriter,
            jsonEncoder: encoder
        )

        _ = await processor.process(mockError, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 60)

        let receivedData = try XCTUnwrap(mockFileDataWriter.receivedData)

        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: receivedData)

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

        XCTAssertEqual(mockFileDataWriter.receivedURL, fileUrl(for: mockEndpointRequest))
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

        let mockFileDataWriter = MockFileDataWriter()
        mockFileDataWriter.writeClosure = {
            expectation.fulfill()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(
            fileManager: mockFileManager,
            fileDataWriter: mockFileDataWriter,
            jsonEncoder: encoder
        )
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        await fulfillment(of: [expectation], timeout: 60)

        let receivedData = try XCTUnwrap(mockFileDataWriter.receivedData)

        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: receivedData)
        let mockRequestBody = try XCTUnwrap(try mockEndpointRequest.endpoint.encodeBody())

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

        XCTAssertEqual(mockFileDataWriter.receivedURL, fileUrl(for: mockEndpointRequest))
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
        let fileName = "\(endpointRequest.sessionId)_\(endpointRequest.endpoint.identifier)_0"
        return responsesDirectory(for: endpointRequest)
            .appendingPathComponent("\(fileName).json")
    }

    func responsesDirectory(for endpointRequest: EndpointRequest) -> URL {
        let responsesDirectory = mockFileManager.temporaryDirectory.appendingPathComponent("responses")
        return responsesDirectory
            .appendingPathComponent(endpointRequest.sessionId)
    }
}
