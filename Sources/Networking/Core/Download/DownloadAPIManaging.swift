//
//  DownloadAPIManaging.swift
//
//
//  Created by Dominika Gajdová on 12.05.2023.
//

import Foundation

// MARK: - Defines Download API managing
/// A download result consisting of `URLSessionDownloadTask` and ``Response``
public typealias DownloadResult = (URLSessionDownloadTask, Response)

/// A definition of an API layer with methods for handling data downloading.
///
/// Recommended to be used as singleton. If you wish to use multiple instances, make sure you manually invalidate url session by calling the `invalidateSession` method.
public protocol DownloadAPIManaging {
    /// List of all currently ongoing download tasks.
    var allTasks: [URLSessionDownloadTask] { get async }
    
    /// Invalidates urlSession instance.
    /// - Parameters:
    ///   - shouldFinishTasks: Indicates whether all currently active tasks should be able to finish before invalidating. Otherwise they will be cancelled.
    func invalidateSession(shouldFinishTasks: Bool)

    /// Initiates a download request for a given endpoint, with optional resumable data and retry configuration.
    /// - Parameters:
    ///   - endpoint: API endpoint requestable definition.
    ///   - resumableData: Optional data the download request will be resumed with.
    ///   - retryConfiguration: Configuration for retrying behaviour.
    /// - Returns: A download result consisting of `URLSessionDownloadTask` and ``Response``
    func downloadRequest(
        _ endpoint: Requestable,
        resumableData: Data?,
        retryConfiguration: RetryConfiguration?
    ) async throws -> DownloadResult
    
    
    /// Provides real time download updates for a given `URLSessionTask`
    /// - Parameter task: The task whose updates are requested.
    /// - Returns: An async stream of download states describing the task's download progress.
    func progressStream(for task: URLSessionTask) -> AsyncStream<URLSessionTask.DownloadState>
}

public extension DownloadAPIManaging {
    /// Initiates a download request for a given fileURL, with optional resumable data and retry configuration.
    /// - Parameters:
    ///   - fileURL: A URL of a file which will be downloaded.
    ///   - resumableData: Optional data the download request will be resumed with.
    ///   - retryConfiguration: Configuration for retrying behaviour.
    /// - Returns: A download result consisting of `URLSessionDownloadTask` and `Response`
    func downloadRequest(
        _ fileURL: URL,
        resumableData: Data? = nil,
        retryConfiguration: RetryConfiguration? = .default
    ) async throws -> DownloadResult {
        try await downloadRequest(
            BasicDownloadRouter(fileURL: fileURL),
            resumableData: resumableData,
            retryConfiguration: retryConfiguration
        )
    }

    // Provide request with default nil resumable data, retry configuration
    func downloadRequest(
        _ endpoint: Requestable,
        resumableData: Data? = nil,
        retryConfiguration: RetryConfiguration? = .default
    ) async throws -> DownloadResult {
        try await downloadRequest(
            endpoint,
            resumableData: resumableData,
            retryConfiguration: retryConfiguration
        )
    }
}
