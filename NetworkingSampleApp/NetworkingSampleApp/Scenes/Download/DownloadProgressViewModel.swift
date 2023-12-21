//
//  DownloadProgressViewModel.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation
import Networking

@MainActor
final class DownloadProgressViewModel: TaskProgressViewModel {
    private let task: URLSessionTask
    
    let isRetryable = false
    private(set) var title: String = ""
    private(set) var status: String = ""
    private(set) var downloadedBytes: String = ""
    private(set) var state: URLSessionTask.State = .running
    private(set) var percentCompleted: Double = 0

    init(task: URLSessionTask) {
        self.task = task
    }
    
    func onAppear() {
        Task {
            let stream = DownloadAPIManager.shared.progressStream(for: task)

            for try await downloadState in stream {
                title = task.currentRequest?.url?.absoluteString ?? "-"
                percentCompleted = downloadState.fractionCompleted * 100
                downloadedBytes = ByteCountFormatter.megaBytesFormatter.string(fromByteCount: downloadState.downloadedBytes)
                state = downloadState.taskState
                status = {
                    if let error = downloadState.error {
                        return "Error: \(error.localizedDescription)"
                    }

                    if let downloadedFileURL = downloadState.downloadedFileURL {
                        return "Downloaded at: \(downloadedFileURL.absoluteString)"
                    }

                    return downloadState.taskState.title
                }()

                objectWillChange.send()
            }
        }
    }
    
    func suspend() {
        task.suspend()
    }
    
    func resume() {
        task.resume()
    }
    
    func cancel() {
        task.cancel()
    }

    func retry() {}
}
