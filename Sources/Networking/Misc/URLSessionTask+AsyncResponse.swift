//
//  URLSessionTask+AsyncResponse.swift
//
//
//  Created by Dominika Gajdová on 12.05.2023.
//

import Foundation
// The @preconcurrency suppresses capture of non-sendable type 'AnyCancellables' warning, which doesn't yet conform to Sendable.
@preconcurrency import Combine

extension URLSessionTask {
    func asyncResponse() async throws -> URLResponse {
        var cancellable: AnyCancellable?
        
        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    cancellable = Publishers.CombineLatest(
                        publisher(for: \.response),
                        publisher(for: \.error)
                    )
                    .first(where: { (response, error) in
                        response != nil || error != nil
                    })
                    .sink { (response, error) in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let response {
                            continuation.resume(returning: response)
                        }
                    }
                }
            },
            onCancel: { [cancellable] in
                cancellable?.cancel()
            }
        )
    }
}
