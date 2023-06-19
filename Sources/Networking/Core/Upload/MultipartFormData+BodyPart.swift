//
//  MultipartFormData+BodyPart.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

public extension MultipartFormData {
    /// Represents an individual part of the `multipart/form-data`.
    struct BodyPart {
        /// The input stream containing the data of the part's body.
        let dataStream: InputStream

        /// The name parameter of the `Content-Disposition` header field.
        let name: String

        /// The size of the part's body.
        let size: UInt64

        /// An optional file parameter of the `Content-Disposition` header field. This value may be provided if the body part represents a content of a file.
        let fileName: String?

        /// An optional value of the `Content-Type` header field.
        let mimeType: String?
    }
}

extension MultipartFormData.BodyPart {
    /// Returns the body part's header fields and values based on the properties of the instance.
    var contentHeaders: [HTTPHeader.HeaderField: String] {
        var disposition = "form-data; name=\"\(name)\""

        if let fileName {
            disposition += "; filename=\"\(fileName)\""
        }

        var headers: [HTTPHeader.HeaderField: String] = [
            .contentDisposition: disposition
        ]

        if let mimeType {
            headers[.contentType] = mimeType
        }

        return headers
    }
}
