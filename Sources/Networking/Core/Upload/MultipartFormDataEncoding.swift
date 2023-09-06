//
//  MultipartFormDataEncoding.swift
//
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

public protocol MultipartFormDataEncoding {
    /// Encodes the specified `MultipartFormData` object into a `Data` object.
    /// - Parameter multipartFormData: The `MultipartFormData` object to encode.
    /// - Returns: A `Data` object containing the encoded `multipartFormData`.
    func encode(_ multipartFormData: MultipartFormData) throws -> Data

    /// Encodes the specified `MultipartFormData` object and writes it to the specified file URL.
    ///
    /// - Parameters:
    ///   - multipartFormData: The `MultipartFormData` object to encode.
    ///   - fileUrl: The file URL to write the encoded data to.
    func encode(_ multipartFormData: MultipartFormData, to fileUrl: URL) throws
}
