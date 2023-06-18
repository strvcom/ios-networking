//
//  MultiFormDataEncoderTests.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Networking
import XCTest

final class MultiFormDataEncoderTests: XCTestCase {
    private let fileManager = FileManager.default

    private var temporaryDirectoryUrl: URL {
        URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        ).appendingPathComponent("multiformdata-encoder-tests")
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try fileManager.createDirectory(
            atPath: temporaryDirectoryUrl.path,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try fileManager.removeItem(at: temporaryDirectoryUrl)
    }

    func test_encode_encodesDataAsExpected() throws {
        let sut = makeSUT()
        let formData = MultiFormData(boundary: "--boundary--123")

        let data1 = Data("Hello".utf8)
        formData.append(data1, name: "first-data")

        let data2 = Data("World".utf8)
        formData.append(data2, name: "second-data", fileName: "file.txt", mimeType: "text/plain")

        let encoded = try sut.encode(formData)
        let expectedString = "--boundary--123\r\n"
            + "Content-Disposition: form-data; name=\"first-data\"\r\n\r\n"
            + "Hello\r\n"
            + "--boundary--123\r\n"
            + "Content-Disposition: form-data; name=\"second-data\"; filename=\"file.txt\"\r\n"
            + "Content-Type: text/plain\r\n\r\n"
            + "World\r\n"
            + "--boundary--123--\r\n"

        XCTAssertEqual(encoded, Data(expectedString.utf8))
    }

    func test_encode_encodesToFileAsExpected() throws {
        let sut = makeSUT()
        let formData = MultiFormData(boundary: "--boundary--123")

        let data = Data("Hello".utf8)
        formData.append(data, name: "first-data")

        let tmpFileUrl = temporaryDirectoryUrl.appendingPathComponent(UUID().uuidString)
        try sut.encode(formData, to: tmpFileUrl)

        let encoded = try Data(contentsOf: tmpFileUrl)

        let expectedString = "--boundary--123\r\n"
            + "Content-Disposition: form-data; name=\"first-data\"\r\n\r\n"
            + "Hello\r\n"
            + "--boundary--123--\r\n"

        XCTAssertEqual(encoded, Data(expectedString.utf8))
    }

    func test_encode_throwsInvalidFileUrl() {
        let sut = makeSUT()
        let formData = MultiFormData()
        let tmpFileUrl = URL(string: "invalid/path")!

        do {
            try sut.encode(formData, to: tmpFileUrl)
            XCTFail("Encoding should have failed.")
        } catch MultiFormData.EncodingError.invalidFileUrl {
        } catch {
            XCTFail("Should have failed with MultiFormData.EncodingError.fileAlreadyExists")
        }
    }

    func test_encode_throwsFileAlreadyExists() {
        let sut = makeSUT()
        let formData = MultiFormData()
        let tmpFileUrl = temporaryDirectoryUrl.appendingPathComponent("file")
        try? sut.encode(formData, to: tmpFileUrl)
        do {
            try sut.encode(formData, to: tmpFileUrl)
            XCTFail("Encoding should have failed.")
        } catch MultiFormData.EncodingError.fileAlreadyExists {
        } catch {
            XCTFail("Should have failed with MultiFormData.EncodingError.fileAlreadyExists")
        }
    }
}

private extension MultiFormDataEncoderTests {
    func makeSUT(fileManager: FileManager = .default) -> MultiFormDataEncoder {
        let sut = MultiFormDataEncoder(fileManager: fileManager)
        return sut
    }
}
