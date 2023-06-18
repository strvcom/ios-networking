//
//  MultiFormData.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

open class MultiFormData {
    private(set) var bodyParts: [BodyPart] = []
    let boundary: String

    public init(boundary: String? = nil) {
        self.boundary = boundary ?? "--boundary-\(UUID().uuidString)"
    }
}

// MARK: - Adding form data
public extension MultiFormData {
    func append(
        _ data: Data,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        let dataStream = InputStream(data: data)
        append(dataStream: dataStream, name: name, fileName: fileName, mimeType: mimeType)
    }

    func append(
        from fileUrl: URL,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) throws {
        let fileName = fileName ?? fileUrl.lastPathComponent

        guard !fileName.isEmpty && !fileUrl.pathExtension.isEmpty else {
            throw EncodingError.invalidFileName(at: fileUrl)
        }

        guard
            !fileUrl.isDirectory && fileUrl.isFileURL,
            let dataStream = InputStream(url: fileUrl)
        else {
            throw EncodingError.invalidFileUrl(fileUrl)
        }

        append(dataStream: dataStream, name: name, fileName: fileName, mimeType: mimeType ?? fileUrl.mimeType)
    }
}

// MARK: - Private
private extension MultiFormData {
    func append(
        dataStream: InputStream,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        bodyParts.append(BodyPart(
            dataStream: dataStream,
            name: name,
            fileName: fileName,
            mimeType: mimeType
        ))
    }
}

// MARK: - Errors
extension MultiFormData {
    public enum EncodingError: LocalizedError {
        case invalidFileUrl(URL)
        case invalidFileName(at: URL)
    }
}
