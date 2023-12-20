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

    init(uploadManager: UploadAPIManaging = UploadAPIManager(requestAdapters: [LoggingInterceptor.shared])) {
        self.uploadManager = uploadManager
    }

    deinit {
        uploadManager.invalidateSession(shouldFinishTasks: false)
    }
}

private extension UploadType {
    var fileName: String {
        switch self {
        case let .data(_, contentType):
            return contentType
        case let .file(url):
            return url.lastPathComponent
        case let .multipart(data, _):
            let dataSize = Int64(data.size)
            let formattedDataSize = ByteCountFormatter.megaBytesFormatter.string(fromByteCount: dataSize)
            return "Form upload of size \(formattedDataSize)"
        }
    }
}

extension UploadService {
    func upload(_ type: UploadType) async throws -> UploadItem {
        let task = try await uploadManager.upload(type, to: SampleAPIConstants.uploadURL)

        return UploadItem(
            id: task.id,
            fileName: type.fileName
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
            taskId: uploadItem.id
        )
    }
}
