//
//  HTTPHeader.swift
//
//
//  Created by Tomas Cejka on 08.09.2021.
//

import Foundation

// MARK: - Constants for http header

enum HTTPHeader {
    enum HeaderField: String {
        case contentType = "Content-Type"
    }

    enum ContentTypeValue: String {
        case json = "application/json"
    }
}
