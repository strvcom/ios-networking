//
//  APICallIdentifying.swift
//  STRV_template
//
//  Created by Tomas Cejka on 08.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

public protocol APICallIdentifying {
    var apiPath: String { get }
    var apiMethod: String { get }
}

public extension Identifiable where Self: APICallIdentifying {
    var identifier: String {
        // solve potential doubled '_' when api path starting by '/'
        // first is path to have method like a divider to avoid ambiguity like users vs users_2
        var normalizedApiPath: String
        if apiPath.starts(with: "/") {
            normalizedApiPath = String(apiPath.dropFirst())
        } else {
            normalizedApiPath = apiPath
        }
        return "\(normalizedApiPath.replacingOccurrences(of: "/", with: "_"))_\(apiMethod.lowercased())"
    }
}

extension URLRequest: APICallIdentifying, Identifiable {
    public var apiPath: String {
        url?.path ?? ""
    }
    
    public var apiMethod: String {
        httpMethod ?? ""
    }
}

public extension Requestable where Self: APICallIdentifying {
    var apiPath: String {
        path
    }
    
    var apiMethod: String {
        method.rawValue
    }
}
