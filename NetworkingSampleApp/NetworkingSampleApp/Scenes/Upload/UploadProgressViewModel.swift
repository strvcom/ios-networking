//
//  UploadItemViewModel.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation
import Networking

@MainActor
final class UploadProgressViewModel: TaskProgressViewModel {
    private let task: UploadTask
    private let uploadManager = UploadAPIManager.shared

    let isRetryable = true

    private(set) var title: String = ""
    private(set) var status: String = ""
    private(set) var downloadedBytes: String = ""
    private(set) var state: URLSessionTask.State = .running
    private(set) var percentCompleted: Double = 0

    init(task: UploadTask) {
        self.task = task
    }

    func onAppear() {
        Task {
            await observeProgress()
        }
    }
    
    func observeProgress() async {
        for await uploadState in await uploadManager.stateStream(for: task.id) {
            title = task.id
            percentCompleted = uploadState.fractionCompleted * 100
            downloadedBytes = ByteCountFormatter.megaBytesFormatter.string(fromByteCount: uploadState.sentBytes)
            state = uploadState.taskState
            status = {
                if let error = uploadState.error {
                    return "Error: \(error.localizedDescription)"
                }

                return uploadState.taskState.title
            }()

            objectWillChange.send()
        }
    }

    func suspend() {
        task.pause()
    }

    func resume() {
        task.resume()
    }

    func cancel() {
        task.cancel()
    }

    func retry() {
        Task {
            try await uploadManager.retry(taskId: task.id)
            await observeProgress()
        }
    }
}
