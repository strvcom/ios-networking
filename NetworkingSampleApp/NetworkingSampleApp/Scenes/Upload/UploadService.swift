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
            to: SampleUploadRouter.image,
            retryConfiguration: .default
        )
        return UploadItem(
            id: task.id,
            fileName: fileName
        )
    }

    func uploadFile(_ fileUrl: URL) async throws -> UploadItem {
        let task = try await uploadManager.upload(
            fromFile: fileUrl,
            to: SampleUploadRouter.file(fileUrl),
            retryConfiguration: .default
        )
        return UploadItem(
            id: task.id,
            fileName: fileUrl.lastPathComponent
        )
    }

    func uploadFormData(_ build: @escaping (MultipartFormData) throws -> Void) async throws -> UploadItem {
        let multipartFormData = MultipartFormData()
        try build(multipartFormData)
        let task = try await uploadManager.upload(
            multipartFormData: multipartFormData,
            to: SampleUploadRouter.multipart(boundary: multipartFormData.boundary),
            retryConfiguration: .default
        )
        return UploadItem(
            id: task.id,
            fileName: "Form upload of size \(multipartFormData.size)"
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

    func retry(_ uploadItem: UploadItem) async throws {
        try await uploadManager.retry(
            taskId: uploadItem.id,
            retryConfiguration: .default
        )
    }
}

private extension UploadAPIManaging {
    func task(with id: String) async -> UploadTask? {
        await allTasks.first { $0.id == id }
    }
}
