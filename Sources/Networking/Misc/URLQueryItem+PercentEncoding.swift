//
//  URLQueryItem+PercentEncoding.swift
//
//
//  Created by Tomas Cejka on 02.01.2024.
//

import Foundation

/// Convenience methods to provide custom percent encoding for URLQueryItem
extension URLQueryItem {
    func plusSignPercentEncoded() -> URLQueryItem {
        var newQueryItem = self
        newQueryItem.value = value?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%2B")
        
        return newQueryItem
    }
    
    func customPercentEncoded(_ value: String) -> URLQueryItem {
        var newQueryItem = self
        newQueryItem.value = value
        return newQueryItem
    }
}
