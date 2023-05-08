//
//  File.swift
//  
//
//  Created by Dominika Gajdová on 08.05.2023.
//

import Foundation

public struct ArrayType {
    let values: [Any]
    let arrayEncoding: ArrayEncoding
    
    public init(_ values: [Any], arrayEncoding: ArrayEncoding = .individual) {
        self.values = values
        self.arrayEncoding = arrayEncoding
    }
}
