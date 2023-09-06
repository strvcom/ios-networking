//
//  MultipartFormDataEncoder.swift
//
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

open class MultipartFormDataEncoder {
    /// A string representing a carriage return and line feed.
    private let crlf = "\r\n"

    /// An instance of `FileManager` used to manage files.
    private let fileManager: FileManager

    /// A read/write stream buffer size in bytes.
    private let streamBufferSize: Int

    /// Creates a `MultipartFormDataEncoder` instance with the specified file manager and stream buffer size.
    ///
    /// - Parameters:
    ///   - fileManager: A `FileManager` used for files management.
    ///   - streamBufferSize: A read/write stream buffer size in bytes. Defaults to 1KB.
    public init(
        fileManager: FileManager = .default,
        streamBufferSize: Int = 1024
    ) {
        self.fileManager = fileManager
        self.streamBufferSize = streamBufferSize
    }
}

// MARK: - MultipartFormDataEncoding
extension MultipartFormDataEncoder: MultipartFormDataEncoding {
    /// The main reason why there are methods to encode data & encode file is similar to `uploadTask(with:from:)` and `uploadTask(with:fromFile:)`  ig one could convert the content of the file to Data using Data(contentsOf:) and use the first method to send data. One has the data available in memory while the second reads the data directly from the file thus doesn't load the data into memory so it is more efficient.
    public func encode(_ multipartFormData: MultipartFormData) throws -> Data {
        var encoded = Data()

        for bodyPart in multipartFormData.bodyParts {
            encoded.append("\(multipartFormData.boundary)\(crlf)")

            let encodedHeaders = encode(bodyPart.contentHeaders)
            encoded.append(encodedHeaders)
            encoded.append("\(crlf)\(crlf)")

            let encodedData = try encode(bodyPart.dataStream)
            encoded.append(encodedData)
            encoded.append("\(crlf)")
        }

        encoded.append("\(multipartFormData.boundary)--\(crlf)")
        return encoded
    }

    public func encode(_ multipartFormData: MultipartFormData, to fileUrl: URL) throws {
        guard fileUrl.isFileURL else {
            throw MultipartFormData.EncodingError.invalidFileUrl(fileUrl)
        }

        guard !fileManager.fileExists(at: fileUrl) else {
            throw MultipartFormData.EncodingError.fileAlreadyExists(for: fileUrl)
        }

        guard let outputStream = OutputStream(url: fileUrl, append: false) else {
            throw MultipartFormData.EncodingError.dataStreamWriteFailed(for: fileUrl)
        }

        try encode(multipartFormData, into: outputStream)
    }
}

// MARK: - Private API
private extension MultipartFormDataEncoder {
    func encode(
        _ multipartFormData: MultipartFormData,
        into outputStream: OutputStream
    ) throws {
        outputStream.open()
        defer { outputStream.close() }

        for bodyPart in multipartFormData.bodyParts {
            let encodedBoundary = "\(multipartFormData.boundary)\(crlf)".data
            try write(encodedBoundary, into: outputStream)

            var encodedHeaders = encode(bodyPart.contentHeaders)
            encodedHeaders.append("\(crlf)\(crlf)")
            try write(encodedHeaders, into: outputStream)

            try write(bodyPart.dataStream, into: outputStream)
            try write("\(crlf)".data, into: outputStream)
        }

        try write("\(multipartFormData.boundary)--\(crlf)".data, into: outputStream)
    }

    func write(
        _ inputStream: InputStream,
        into outputStream: OutputStream
    ) throws {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: streamBufferSize)
        inputStream.open()
        defer {
            inputStream.close()
            buffer.deallocate()
        }

        while inputStream.hasBytesAvailable && outputStream.hasSpaceAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: streamBufferSize)

            if bytesRead == -1, let error = inputStream.streamError {
                throw MultipartFormData.EncodingError.dataStreamReadFailed(with: error)
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
                throw MultipartFormData.EncodingError.dataStreamReadFailed(with: error)
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
            .map { "\($0.key.rawValue): \($0.value)" }
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
