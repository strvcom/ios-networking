//
//  HTTPMethod.swift
//  Networking
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation

/// An HTTP request method.
public enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case head = "HEAD"
    case patch = "PATCH"
    case option = "OPTION"
    case delete = "DELETE"
}
