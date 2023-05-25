//
//  ThreadSafeDictionary.swift
//  
//
//  Created by Dominika Gajdová on 25.05.2023.
//

import Foundation

/// A thread safe generic wrapper for dictionary.
actor ThreadSafeDictionary<Key: Hashable, Value> {
    private var values = [Key: Value]()
    
    func getValues() -> [Key: Value] {
        values
    }
    
    func getValue(for task: Key) -> Value? {
        values[task]
    }
    
    func set(value: Value?, for task: Key) {
        values[task] = value        
    }
    
    /// Updates the property of a given keyPath.
    func update<Type>(
        task: Key,
        for keyPath: WritableKeyPath<Value, Type>,
        with value: Type
    ) {
        if var state = values[task] {
            state[keyPath: keyPath] = value
            values[task] = state
        }
    }
}
