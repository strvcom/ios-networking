//
//  MultiFormData+BodyPart.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

public extension MultiFormData {
    struct BodyPart {
        let dataStream: InputStream
        let name: String
        let size: UInt64
        let fileName: String?
        let mimeType: String?
    }
}

extension MultiFormData.BodyPart {
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
