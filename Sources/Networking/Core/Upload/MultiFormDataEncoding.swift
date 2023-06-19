//
//  MultiFormDataEncoding.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

public protocol MultiFormDataEncoding {
    /// Encodes the specified `MultiFormData` object into a `Data` object.
    /// - Parameter multiFormData: The `MultiFormData` object to encode.
    /// - Returns: A `Data` object containing the encoded `multiFormData`.
    func encode(_ multiFormData: MultiFormData) throws -> Data

    /// Encodes the specified `MultiFormData` object and writes it to the specified file URL.
    ///
    /// - Parameters:
    ///   - multiFormData: The `MultiFormData` object to encode.
    ///   - fileUrl: The file URL to write the encoded data to.
    func encode(_ multiFormData: MultiFormData, to fileUrl: URL) throws
}
