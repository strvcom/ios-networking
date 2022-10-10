//
//  RequestDataType.swift
//  Networking
//
//  Created by Tomas Cejka on 11.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines various request data types to be sent in body

/// Data type of request body
public enum RequestDataType {
    /// Encodable data type, sets HTTP header content type to application/json
    case encodable(Encodable, encoder: JSONEncoder = JSONEncoder())
    /// Custom encoded data for request body with provided content type for HTTP header
    case custom(encodedData: Data, contentType: String)
}
