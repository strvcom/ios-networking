//
//  File.swift
//  
//
//  Created by Dominika Gajdová on 08.05.2023.
//

import Foundation

/// Array parameter type for associated values with array encoding option.
///
/// The following example shows the use.
///
///     var urlParameters: [String: Any]? {
///         ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .individual)]
///     }

public struct ArrayParameter {
    let values: [Any]
    let arrayEncoding: ArrayEncoding
    
    public init(_ values: [Any], arrayEncoding: ArrayEncoding = .individual) {
        self.values = values
        self.arrayEncoding = arrayEncoding
    }
}
