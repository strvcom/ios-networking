//
//  MultiFormDataEncoding.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation

public protocol MultiFormDataEncoding {
    func encode(_ multiFormData: MultiFormData) throws -> Data
    func encode(_ multiFormData: MultiFormData, to fileUrl: URL) throws
}
