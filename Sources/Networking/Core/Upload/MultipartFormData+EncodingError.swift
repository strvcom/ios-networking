//
//  MultipartFormData+EncodingError.swift
//
//
//  Created by Tony Ngo on 19.06.2023.
//

import Foundation

public extension MultipartFormData {
    enum EncodingError: LocalizedError {
        case invalidFileUrl(URL)
        case invalidFileName(for: URL)
        case missingFileSize(for: URL)
        case dataStreamReadFailed(with: Error)
        case dataStreamWriteFailed(for: URL)
        case fileAlreadyExists(for: URL)
    }
}
