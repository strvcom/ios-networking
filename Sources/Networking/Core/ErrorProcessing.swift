//
//  ErrorProcessing.swift
//  Networking
//
//  Created by Dominika Gajdová on 05.12.2022.
//  Copyright © 2021 STRV. All rights reserved.

import Foundation

/// A type that is able to customize error returned after failed network request.
@NetworkingActor
public protocol ErrorProcessing: Sendable {
    /// Modifies a given `Error`.
    /// - Parameters:
    ///   - error: The error to be processed.
    ///   - endpointRequest: An endpoint request wrapper.
    /// - Returns: The processed `Error`.
    func process(_ error: Error, for endpointRequest: EndpointRequest) async -> Error
}

/// Array extension to avoid boilerplate
public extension Array where Element == ErrorProcessing {
    /// Applies the process method to all objects in a sequence.
    /// - Parameters:
    ///   - error: The error to be processed.
    /// - Returns: An `Error` processed by all objects in a sequence.
    func process(_ error: Error, for endpointRequest: EndpointRequest) async -> Error {
        await asyncReduce(error) { errorResult, errorProcessing in
            await errorProcessing.process(errorResult, for: endpointRequest)
        }
    }
}
