//
//  FormUploadsViewModel.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 19.06.2023.
//

import Foundation
import OSLog

@MainActor
final class FormUploadsViewModel: ObservableObject {
    @Published var username = ""
    @Published var fileUrl: URL?
    @Published var isErrorAlertPresented = false
    @Published private(set) var error: Error?
    @Published private(set) var uploadItemViewModels: [UploadItemViewModel] = []

    var selectedFileName: String {
        let resources = try? fileUrl?.resourceValues(forKeys:[.fileSizeKey])
        let fileSize = (resources?.fileSize ?? 0) / 1_000_000
        var fileName = fileUrl?.lastPathComponent ?? ""
        if fileSize > 0 { fileName += "\n\(fileSize) MB" }
        return fileName
    }

    private let uploadService: UploadService

    init(uploadService: UploadService = .init()) {
        self.uploadService = uploadService
    }
}

extension FormUploadsViewModel {
    func uploadForm() {
        Task {
            do {
                let uploadItem = try await uploadService.uploadFormData { form in
                    form.append(Data(self.username.utf8), name: "username-textfield")

                    if let fileUrl = self.fileUrl {
                        try form.append(from: fileUrl, name: "attachment")
                    }
                }

                uploadItemViewModels.append(UploadItemViewModel(
                    item: uploadItem,
                    uploadService: uploadService
                ))

                username = ""
                fileUrl = nil
            } catch {
                os_log("❌ FormUploadsViewModel failed to upload form with error: \(error.localizedDescription)")
                self.error = error
                self.isErrorAlertPresented = true
            }
        }
    }
}
