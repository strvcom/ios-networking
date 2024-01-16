//
//  MultipartFormData.swift
//
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

/// The `MultipartFormData` class provides a convenient way to handle multipart form data.
/// It allows you to construct a multipart form data payload by adding multiple body parts, each representing a separate piece of data.
open class MultipartFormData {
    /// The total size of the `multipart/form-data`.
    /// It is calculated as the sum of sizes of all the body parts added to the `MultipartFormData` instance.
    public var size: UInt64 {
        bodyParts.reduce(0) { $0 + $1.size }
    }

    /// Represents the boundary string used to separate the different parts of the multipart form data.
    /// It is a unique string that acts as a delimiter between each body part.
    public let boundary: String

    private(set) var bodyParts: [BodyPart] = []

    /// Initializes a new instance of `MultipartFormData` with an optional boundary string.
    /// - Parameter boundary: A custom boundary string to be used for separating the body parts in the multipart form data.
    /// If not provided, a unique boundary string is generated using a combination of "--boundary-" and a UUID.
    public init(boundary: String? = nil) {
        self.boundary = boundary ?? "----boundary-\(UUID().uuidString)"
    }
}

// MARK: - Adding form data
public extension MultipartFormData {
    /// Adds a body part to the multipart form data payload using the specified `data`.
    ///
    /// - Parameters:
    ///   - data: The data to be added to the payload.
    ///   - name: The name parameter of the `Content-Disposition` header field associated with this body part.
    ///   - fileName: An optional filename parameter of the `Content-Disposition` header field associated with this body part.
    ///   - mimeType: An optional MIME type of the body part.
    func append(
        _ data: Data,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        let dataStream = InputStream(data: data)
        append(
            dataStream: dataStream,
            name: name,
            size: UInt64(data.count),
            fileName: fileName,
            mimeType: mimeType
        )
    }

    /// Adds a body part to the multipart form data payload using data from a file specified by its URL.
    ///
    /// - Parameters:
    ///   - fileUrl: The URL of the file containing the data for the body part.
    ///   - name: The name parameter of the `Content-Disposition` header field associated with this body part.
    ///   - fileName: An optional filename parameter of the `Content-Disposition` header field associated with this body part. If not provided, the last path component of the fileUrl is used as the filename (if any).
    ///   - mimeType: An optional MIME type of the body part. If not provided, the MIME type is inferred from the file extension of the file.
    func append(
        from fileUrl: URL,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) throws {
        let fileName = fileName ?? fileUrl.lastPathComponent

        guard !fileName.isEmpty && !fileUrl.pathExtension.isEmpty else {
            throw EncodingError.invalidFileName(for: fileUrl)
        }

        guard
            !fileUrl.isDirectory && fileUrl.isFileURL,
            let dataStream = InputStream(url: fileUrl)
        else {
            throw EncodingError.invalidFileUrl(fileUrl)
        }

        guard let fileSize = fileUrl.fileSize else {
            throw EncodingError.missingFileSize(for: fileUrl)
        }

        append(
            dataStream: dataStream,
            name: name,
            size: UInt64(fileSize),
            fileName: fileName,
            mimeType: mimeType ?? fileUrl.mimeType
        )
    }
}

// MARK: - Private
private extension MultipartFormData {
    func append(
        dataStream: InputStream,
        name: String,
        size: UInt64,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        bodyParts.append(BodyPart(
            dataStream: dataStream,
            name: name,
            size: size,
            fileName: fileName,
            mimeType: mimeType
        ))
    }
}
