//
//  DownloadAPIManaging.swift
//  
//
//  Created by Dominika Gajdová on 12.05.2023.
//

import Foundation

// MARK: - Defines Download API managing
public typealias DownloadResult = (URLSessionDownloadTask, Response)

public protocol DownloadAPIManaging {
    var allTasks: [URLSessionDownloadTask] { get async }
    
    func downloadRequest(
        _ endpoint: Requestable,
        resumableData: Data?,
        retryConfiguration: RetryConfiguration?
    ) async throws -> DownloadResult
    
    func progressStream(for task: URLSessionTask) -> AsyncStream<URLSessionTask.DownloadState>
}

// MARK: - Provide request with default nil resumable data, retry configuration
public extension DownloadAPIManaging {
    func downloadRequest(
        _ endpoint: Requestable,
        resumableData: Data? = nil,
        retryConfiguration: RetryConfiguration? = .default
    ) async throws -> DownloadResult {
        try await downloadRequest(endpoint, resumableData: resumableData, retryConfiguration: retryConfiguration)
    }
}
