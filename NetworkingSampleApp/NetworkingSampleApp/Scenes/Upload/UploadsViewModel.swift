//
//  UploadsViewModel.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation
import OSLog

@MainActor
final class UploadsViewModel: ObservableObject {
    @Published var isErrorAlertPresented = false
    @Published private(set) var error: Error?
    @Published private(set) var uploadItemViewModels: [UploadItemViewModel] = []

    private let uploadService: UploadService

    init(uploadService: UploadService = UploadService()) {
        self.uploadService = uploadService
    }
}

extension UploadsViewModel {
    func uploadImage(result: Result<Data?, Error>) {
        Task {
            do {
                if let imageData = try result.get() {
                    let uploadItem = try await uploadService.upload(.data(imageData, contentType: "image/png"))
                    uploadItemViewModels.append(UploadItemViewModel(
                        item: uploadItem,
                        uploadService: uploadService
                    ))
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
                let uploadItem = try await uploadService.upload(.file(fileUrl))
                uploadItemViewModels.append(UploadItemViewModel(
                    item: uploadItem,
                    uploadService: uploadService
                ))
            } catch {
                os_log("❌ UploadsViewModel failed to upload with error: \(error.localizedDescription)")
                self.error = error
                self.isErrorAlertPresented = true
            }
        }
    }
}
