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
    private let fileManager = FileManager.default
    
    struct MockBody: Codable {
        let parameter: String
    }
    
    enum MockRouter: Requestable {
        case testStoringGet
        case testStoringPost
        case testStoringImage
        
        var baseURL: URL {
            URL(string: "https://endpointRequestStorageProcessor.tests")!
        }

        var path: String {
            switch self {
            case .testStoringGet:
                return "storing"
            case .testStoringPost:
                return "storing"
            case .testStoringImage:
                return "image"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .testStoringGet, .testStoringImage:
                return .get
            case .testStoringPost:
                return .post
            }
        }
        var urlParameters: [String : Any]? {
            switch self {
            case .testStoringGet, .testStoringPost, .testStoringImage:
                return ["query": "mock"]
            }
        }
        
        var headers: [String : String]? {
            switch self {
            case .testStoringGet, .testStoringPost, .testStoringImage:
                return ["mockRequestHeader": "mock"]
            }
        }
        
        var dataType: RequestDataType? {
            switch self {
            case .testStoringGet, .testStoringImage:
                return nil
            case .testStoringPost:
                return .encodable(MockBody(parameter: "mock"))
            }
        }
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
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(fileManager: fileManager, jsonEncoder: encoder)
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)
        
        // The storing runs on background thread so we need to wait before reading the file
        try await Task.sleep(nanoseconds: 1000000000)
        
        let fileUrl = fileUrl(for: mockEndpointRequest)

        guard let data = fileManager.contents(atPath: fileUrl.path) else {
            XCTAssert(false, "File doesn't exist")
            return
        }
        
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)
        
        XCTAssert(
            model.statusCode == 200 &&
            model.method == "GET" &&
            model.path == mockEndpointRequest.endpoint.path &&
            model.parameters == ["query": "mock"] &&
            model.requestBody == nil &&
            model.requestBodyString == nil &&
            model.requestHeaders == mockURLRequest.allHTTPHeaderFields &&
            model.responseBody == mockResponseData &&
            model.responseBodyString == String(data: mockResponseData, encoding: .utf8) &&
            model.responseHeaders == ["mockResponseHeader": "mock"]
        )
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
        let mockResponseData = UIImage(systemName: "pencil")!.pngData()!
        let mockResponse = (mockResponseData, mockURLResponse)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(fileManager: fileManager, jsonEncoder: encoder)
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)
        
        // The storing runs on background thread so we need to wait before reading the file
        try await Task.sleep(nanoseconds: 1000000000)
        
        let fileUrl = fileUrl(for: mockEndpointRequest)

        guard let data = fileManager.contents(atPath: fileUrl.path) else {
            XCTAssert(false, "File doesn't exist")
            return
        }
        
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)
        
        XCTAssert(
            model.statusCode == 200 &&
            model.method == "GET" &&
            model.path == mockEndpointRequest.endpoint.path &&
            model.parameters == ["query": "mock"] &&
            model.requestBody == nil &&
            model.requestBodyString == nil &&
            model.requestHeaders == mockURLRequest.allHTTPHeaderFields &&
            model.responseBody == mockResponseData &&
            model.responseBodyString == String(data: mockResponseData, encoding: .utf8) &&
            model.responseHeaders == ["mockResponseHeader": "mock"]
        )
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
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let processor = EndpointRequestStorageProcessor(fileManager: fileManager, jsonEncoder: encoder)
        _ = try await processor.process(mockResponse, with: mockURLRequest, for: mockEndpointRequest)

        // The storing runs on background thread so we need to wait before reading the file
        try await Task.sleep(nanoseconds: 1000000000)
        
        let fileUrl = fileUrl(for: mockEndpointRequest)

        guard let data = fileManager.contents(atPath: fileUrl.path) else {
            XCTAssert(false, "File doesn't exist")
            return
        }
                
        let model = try JSONDecoder().decode(EndpointRequestStorageModel.self, from: data)
        let mockRequestBody = try mockEndpointRequest.endpoint.encodeBody()!
        
        XCTAssert(
            model.statusCode == 200 &&
            model.method == "POST" &&
            model.path == mockEndpointRequest.endpoint.path &&
            model.parameters == ["query": "mock"] &&
            model.requestBody == mockRequestBody &&
            model.requestBodyString == String(data: mockRequestBody, encoding: .utf8) &&
            model.requestHeaders == mockURLRequest.allHTTPHeaderFields &&
            model.responseBody == mockResponseData &&
            model.responseBodyString == String(data: mockResponseData, encoding: .utf8) &&
            model.responseHeaders == ["mockResponseHeader": "mock"]
        )
    }
    
    static var allTests = [
        ("testResponseStaysTheSameAfterStoringData", testResponseStaysTheSameAfterStoringData),
        ("testStoredDataForGetRequestWithJSONResponse", testStoredDataForGetRequestWithJSONResponse),
        ("testStoredDataForGetRequestWithImageResponse", testStoredDataForGetRequestWithImageResponse),
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
