//
//  UploadItemViewModel.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation

@MainActor
final class UploadItemViewModel: ObservableObject {
    @Published private(set) var progress: Double = 0
    @Published private(set) var formattedProgress: String = ""
    @Published private(set) var isPaused = false
    @Published private(set) var isCancelled = false
    @Published private(set) var isRetryable = false

    let fileName: String
    let totalProgress = 100.0

    private let item: UploadItem
    private let uploadService: UploadService

    init(item: UploadItem, uploadService: UploadService) {
        self.item = item
        self.fileName = item.fileName
        self.uploadService = uploadService
    }
}

extension UploadItemViewModel {
    func observeProgress() async {
        let uploadStateStream = await uploadService.uploadStateStream(for: item.id)
        for await state in uploadStateStream {
            progress = state.fractionCompleted * 100
            formattedProgress = String(format: "%.2f", progress) + "%"
            isPaused = state.isSuspended
            isCancelled = state.cancelled
            isRetryable = state.cancelled || state.timedOut
        }
    }

    func pause() {
        Task {
            await uploadService.pause(taskId: item.id)
            isPaused = true
            isRetryable = false
        }
    }

    func resume() {
        Task {
            await uploadService.resume(taskId: item.id)
            isPaused = false
            isRetryable = false
        }
    }

    func cancel() {
        Task {
            await uploadService.cancel(taskId: item.id)
            isCancelled = true
            isRetryable = true
        }
    }
}
