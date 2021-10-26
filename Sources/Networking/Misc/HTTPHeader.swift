//
//  HTTPHeader.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Foundation

// MARK: - Constants for http header

/// Constants for HTTP header keys or values
public enum HTTPHeader {
    /// Constants for http header key
    public enum HeaderField: String {
        case contentType = "Content-Type"
    }

    /// Constants for values for http header content type key
    public enum ContentTypeValue: String {
        case json = "application/json"
    }
}
