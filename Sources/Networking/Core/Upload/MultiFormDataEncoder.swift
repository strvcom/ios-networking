//
//  MultiFormDataEncoder.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

open class MultiFormDataEncoder {
    private let crlf = "\r\n"

    private let fileManager: FileManager
    private let streamBufferSize: Int

    public init(
        fileManager: FileManager = .default,
        streamBufferSize: Int = 1024
    ) {
        self.fileManager = fileManager
        self.streamBufferSize = streamBufferSize
    }
}

// MARK: - MultiFormDataEncoding
extension MultiFormDataEncoder: MultiFormDataEncoding {
    public func encode(_ multiFormData: MultiFormData) throws -> Data {
        var encoded = Data()

        for bodyPart in multiFormData.bodyParts {
            encoded.append("\(multiFormData.boundary)\(crlf)")

            let encodedHeaders = encode(bodyPart.contentHeaders)
            encoded.append(encodedHeaders)
            encoded.append("\(crlf)\(crlf)")

            let encodedData = try encode(bodyPart.dataStream)
            encoded.append(encodedData)
            encoded.append("\(crlf)")
        }

        encoded.append("\(multiFormData.boundary)--\(crlf)")
        return encoded
    }

    public func encode(_ multiFormData: MultiFormData, to fileUrl: URL) throws {
        guard fileUrl.isFileURL else {
            throw MultiFormData.EncodingError.invalidFileUrl(fileUrl)
        }

        guard !fileManager.fileExists(at: fileUrl) else {
            throw MultiFormData.EncodingError.fileAlreadyExists(at: fileUrl)
        }

        guard let outputStream = OutputStream(url: fileUrl, append: false) else {
            throw MultiFormData.EncodingError.dataStreamWriteFailed(at: fileUrl)
        }

        try encode(multiFormData, into: outputStream)
    }
}

private extension MultiFormDataEncoder {
    func encode(_ multiFormData: MultiFormData, into outputStream: OutputStream) throws {
        outputStream.open()
        defer { outputStream.close() }

        for bodyPart in multiFormData.bodyParts {
            let encodedBoundary = "\(multiFormData.boundary)\(crlf)".data
            try write(encodedBoundary, into: outputStream)

            var encodedHeaders = encode(bodyPart.contentHeaders)
            encodedHeaders.append("\(crlf)\(crlf)")
            try write(encodedHeaders, into: outputStream)

            try write(bodyPart.dataStream, into: outputStream)
            try write("\(crlf)".data, into: outputStream)
        }

        try write("\(multiFormData.boundary)--\(crlf)".data, into: outputStream)
    }

    func write(_ inputStream: InputStream, into outputStream: OutputStream) throws {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: streamBufferSize)
        inputStream.open()
        defer {
            inputStream.close()
            buffer.deallocate()
        }

        while inputStream.hasBytesAvailable && outputStream.hasSpaceAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: streamBufferSize)

            if bytesRead == -1, let error = inputStream.streamError {
                throw MultiFormData.EncodingError.dataStreamReadFailed(with: error)
            }

            if bytesRead > 0 {
                outputStream.write(buffer, maxLength: bytesRead)
            }
        }
    }

    func write(_ data: Data, into outputStream: OutputStream) throws {
        let inputStream = InputStream(data: data)
        try write(inputStream, into: outputStream)
    }

    func encode(_ dataStream: InputStream) throws -> Data {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: streamBufferSize)
        dataStream.open()

        defer {
            dataStream.close()
            buffer.deallocate()
        }

        var encoded = Data()
        while dataStream.hasBytesAvailable {
            let bytesRead = dataStream.read(buffer, maxLength: streamBufferSize)

            if bytesRead == -1, let error = dataStream.streamError {
                throw MultiFormData.EncodingError.dataStreamReadFailed(with: error)
            }

            if bytesRead > 0 {
                encoded.append(buffer, count: bytesRead)
            }
        }
        return encoded
    }

    func encode(_ contentHeaders: [HTTPHeader.HeaderField: String]) -> Data {
        var encoded = Data()

        // Encode headers in a deterministic manner for easier testing
        let encodedHeaders = contentHeaders
            .sorted(by: { $0.key.rawValue < $1.key.rawValue })
            .map { "\($0.key.rawValue): \($0.value)"}
            .joined(separator: "\(crlf)")

        encoded.append(encodedHeaders)
        return encoded
    }
}

private extension FileManager {
    func fileExists(at fileUrl: URL) -> Bool {
        if #available(macOS 13.0, iOS 16.0, *) {
            return fileExists(atPath: fileUrl.path())
        } else {
            return fileExists(atPath: fileUrl.path)
        }
    }
}

private extension String {
    var data: Data {
        Data(self.utf8)
    }
}

private extension Data {
    mutating func append(_ string: String) {
        self.append(string.data)
    }
}
