//
//  URLQueryItem+PercentEncoding.swift
//
//
//  Created by Tomas Cejka on 02.01.2024.
//

import Foundation

/// Convenience methods to provide custom percent encoding for URLQueryItem
extension URLQueryItem {
    
    func percentEncoded() -> URLQueryItem {
        var newQueryItem = self
        newQueryItem.name = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        newQueryItem.value = value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        return newQueryItem
    }
}
