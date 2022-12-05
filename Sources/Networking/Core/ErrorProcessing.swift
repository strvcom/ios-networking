//
//  ErrorProcessing.swift
//  Networking
//
//  Created by Dominika Gajdová on 05.12.2022.
//  Copyright © 2021 STRV. All rights reserved.

import Foundation

/// A type that is able to customize error returned after failed network request.
public protocol ErrorProcessing {
    func process(_ error: Error) -> Error
}

// MARK: - Array extension to avoid boilerplate
public extension Array where Element == ErrorProcessing {
    /// Applies the process method to all objects in a sequence.
    /// - Parameters:
    ///   - error: The error to be procesed.
    /// - Returns:An `Error` processed by all objects in a sequence.
    func process(_ error: Error) -> Error {
        reduce(error) { errorResult, errorProcessing in
            errorProcessing.process(errorResult)
        }
    }
}
