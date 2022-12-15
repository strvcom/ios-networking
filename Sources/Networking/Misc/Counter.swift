//
//  File.swift
//  
//
//  Created by Matej Molnár on 14.12.2022.
//

import Foundation

/// A thread safe wrapper for count dictionary.
actor Counter {
    private var dict = [String: Int]()
    
    func count(for key: String) -> Int {
        dict[key] ?? 0
    }
    
    func increment(for key: String) {
        dict[key] = (dict[key] ?? 0) + 1
    }
    
    func reset(for key: String) {
        dict.removeValue(forKey: key)
    }
}
