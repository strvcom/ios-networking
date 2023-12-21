//
//  UploadItemViewModel.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation
import Networking

@MainActor
final class UploadItemViewModel: ObservableObject {
    @Published private(set) var progress: Double = 0
    @Published private(set) var formattedProgress: String = ""
    @Published private(set) var isPaused = false
    @Published private(set) var isCancelled = false
    @Published private(set) var isRetryable = false

    var stateTitle: String {
        isCancelled
            ? "Cancelled"
            : isCompleted ? "Completed" : formattedProgress
    }

    var isCompleted: Bool { progress == 100 }

    let fileName: String
    let totalProgress = 100.0

    private let task: UploadTask
    private let uploadManager = UploadAPIManager.shared

    init(task: UploadTask) {
        self.task = task
        self.fileName = task.id
    }
}

extension UploadItemViewModel {
    func observeProgress() async {
        for await state in await uploadManager.stateStream(for: task.id) {
            progress = state.fractionCompleted * 100
            formattedProgress = String(format: "%.2f", progress) + "%"
            isPaused = state.isSuspended
            isCancelled = state.cancelled
            isRetryable = state.cancelled || state.timedOut || state.error != nil
        }
    }

    func pause() {
        Task {
            task.pause()
            isPaused = true
            isRetryable = false
        }
    }

    func resume() {
        Task {
            task.resume()
            isPaused = false
            isRetryable = false
        }
    }

    func cancel() {
        Task {
            task.cancel()
            isCancelled = true
            isRetryable = true
        }
    }

    func retry() {
        Task {
            try await uploadManager.retry(taskId: task.id)
            await observeProgress()
        }
    }
}
