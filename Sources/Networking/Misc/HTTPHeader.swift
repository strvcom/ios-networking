//
//  HTTPHeader.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Foundation

// MARK: - Constants for http header

/// A namespace for constants of HTTP header keys or values.
public enum HTTPHeader {
    /// Constants that describe HTTP header keys.
    public enum HeaderField: String {
        case contentType = "Content-Type"
        case authorization = "Authorization"
    }

    /// Constants that describe values for HTTP header content type keys.
    public enum ContentTypeValue: String {
        case json = "application/json"
    }
}
