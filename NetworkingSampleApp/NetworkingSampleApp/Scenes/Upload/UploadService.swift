//
//  UploadService.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation
import Networking

final class UploadService {
    private let uploadManager: UploadAPIManaging

    init(uploadManager: UploadAPIManaging) {
        self.uploadManager = uploadManager
    }

    deinit {
        uploadManager.invalidateSession(shouldFinishTasks: false)
    }
}

extension UploadService {
    func uploadImage(_ data: Data, fileName: String) async throws -> UploadItem {
        let task = try await uploadManager.upload(
            data: data,
            to: SampleUploadRouter.image
        )
        return UploadItem(
            id: task.id,
            fileName: fileName
        )
    }

    func uploadFile(_ fileUrl: URL) async throws -> UploadItem {
        let task = try await uploadManager.upload(
            fromFile: fileUrl,
            to: SampleUploadRouter.file(fileUrl)
        )
        return UploadItem(
            id: task.id,
            fileName: fileUrl.lastPathComponent
        )
    }

    func uploadStateStream(for uploadTaskId: String) async -> UploadAPIManaging.StateStream {
        await uploadManager.stateStream(for: uploadTaskId)
    }

    func pause(taskId: String) async {
        await uploadManager.task(with: taskId)?.pause()
    }

    func resume(taskId: String) async {
        await uploadManager.task(with: taskId)?.resume()
    }

    func cancel(taskId: String) async {
        await uploadManager.task(with: taskId)?.cancel()
    }
}

private extension UploadAPIManaging {
    func task(with id: String) async -> UploadTask? {
        await allTasks.first { $0.id == id }
    }
}
