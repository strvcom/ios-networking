//
//  UploadsViewModel.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation

@MainActor
final class UploadsViewModel: ObservableObject {
    @Published var error: Error?
    @Published private(set) var uploadItemViewModels: [UploadItemViewModel] = []

    private let uploadService: UploadService

    init(uploadService: UploadService) {
        self.uploadService = uploadService
    }
}

extension UploadsViewModel {
    func uploadImage(_ imageData: Data, fileName: String?) async {
        do {
            let uploadItem = try await uploadService.uploadImage(
                imageData,
                fileName: fileName ?? ""
            )
            uploadItemViewModels.append(UploadItemViewModel(item: uploadItem, uploadService: uploadService))
        } catch {
            print("Failed to upload with error", error)
            self.error = error
        }
    }

    func uploadFile(at fileUrl: URL) async {
        do {
            let uploadItem = try await uploadService.uploadFile(fileUrl)
            uploadItemViewModels.append(UploadItemViewModel(item: uploadItem, uploadService: uploadService))
        } catch {
            print("Failed to upload with error", error)
            self.error = error
        }
    }
}
