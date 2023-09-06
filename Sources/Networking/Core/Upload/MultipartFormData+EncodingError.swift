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
        case invalidFileName(at: URL)
        case missingFileSize(for: URL)
        case dataStreamReadFailed(with: Error)
        case dataStreamWriteFailed(at: URL)
        case fileAlreadyExists(at: URL)
    }
}
