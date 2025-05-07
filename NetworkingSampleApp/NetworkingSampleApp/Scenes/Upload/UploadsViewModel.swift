//
//  UploadsViewModel.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation
import Networking
import OSLog

@MainActor
final class UploadsViewModel: ObservableObject {
    @Published var formUsername = ""
    @Published var formFileUrl: URL?
    @Published private(set) var uploadTasks: [UploadTask] = []
    @Published private(set) var error: Error?
    @Published var isErrorAlertPresented = false

    @NetworkingActor
    private lazy var uploadManager = UploadAPIManager.shared

    var formSelectedFileName: String {
        let fileSize = Int64(formFileUrl?.fileSize ?? 0)
        var fileName = formFileUrl?.lastPathComponent ?? ""
        let formattedFileSize = ByteCountFormatter.megaBytesFormatter.string(fromByteCount: fileSize)
        if fileSize > 0 { fileName += "\n\(formattedFileSize)" }
        return fileName
    }
}

extension UploadsViewModel {
    func loadTasks() async {
        uploadTasks = await uploadManager.activeTasks
    }

    func uploadImage(result: Result<Data?, Error>) {
        Task {
            do {
                if let imageData = try result.get() {
                    let uploadTask = try await uploadManager.upload(
                        .data(
                            imageData,
                            contentType: "image/png"
                        ),
                        to: SampleAPIConstants.uploadURL
                    )
                    uploadTasks.append(uploadTask)
                }
            } catch {
                os_log("❌ UploadsViewModel failed to upload with error: \(error.localizedDescription)")
                self.error = error
                self.isErrorAlertPresented = true
            }
        }
    }

    func uploadFile(result: Result<URL, Error>) {
        Task {
            do {
                let fileUrl = try result.get()
                let uploadTask = try await uploadManager.upload(.file(fileUrl), to: SampleAPIConstants.uploadURL)
                uploadTasks.append(uploadTask)
            } catch {
                os_log("❌ UploadsViewModel failed to upload with error: \(error.localizedDescription)")
                self.error = error
                self.isErrorAlertPresented = true
            }
        }
    }

    func uploadForm() {
        Task {
            do {
                let multipartFormData = try createMultipartFormData()
                let uploadTask = try await uploadManager.upload(
                    .multipart(data: multipartFormData, sizeThreshold: 10_000_000),
                    to: SampleAPIConstants.uploadURL
                )
                uploadTasks.append(uploadTask)

                formUsername = ""
                formFileUrl = nil
            } catch {
                os_log("❌ FormUploadsViewModel failed to upload form with error: \(error.localizedDescription)")
                self.error = error
                self.isErrorAlertPresented = true
            }
        }
    }
}

// MARK: - Prepare multipartForm data
private extension UploadsViewModel {
    func createMultipartFormData() throws -> MultipartFormData {
        var multipartFormData = MultipartFormData()
        multipartFormData.append(Data(formUsername.utf8), name: "username-textfield")
        if let formFileUrl {
            try multipartFormData.append(from: formFileUrl, name: "attachment")
        }
        return multipartFormData
    }
}
