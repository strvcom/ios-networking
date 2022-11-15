//
//  Sequence+Convenience.swift
//  
//
//  Created by Tomas Cejka on 15.11.2022.
//

import Foundation

/// Convenience methods for ``Sequence``
extension Sequence {
    func asyncReduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: ((Result, Element) async throws -> Result)
    ) async rethrows -> Result {
        var result = initialResult
        for element in self {
            result = try await nextPartialResult(result, element)
        }
        return result
    }
}
