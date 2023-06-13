//
//  UploadsView.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import SwiftUI
import PhotosUI

struct UploadsView: View {
    @ObservedObject var viewModel: UploadsViewModel
    @State var isPhotosPickerPresented = false
    @State var isFileImporterPresented = false
    @State var selectedPhotoPickerItem: PhotosPickerItem?

    var body: some View {
        List {
            Section("Upload") {
                Button("Photo") { isPhotosPickerPresented = true }
                    .photosPicker(
                        isPresented: $isPhotosPickerPresented,
                        selection: $selectedPhotoPickerItem,
                        matching: .images
                    )
                    .onChange(of: selectedPhotoPickerItem) { photo in
                        Task {
                            if let data = try? await photo?.loadTransferable(type: Data.self) {
                                await viewModel.uploadImage(
                                    data,
                                    fileName: selectedPhotoPickerItem?.supportedContentTypes.first?.preferredFilenameExtension
                                )
                            }
                        }
                    }

                Button("File") { isFileImporterPresented = true }
                    .fileImporter(
                        isPresented: $isFileImporterPresented,
                        allowedContentTypes: [.mp3, .mpeg4Movie]
                    ) { result in
                        Task {
                            if let fileUrl = try? result.get() {
                                await viewModel.uploadFile(at: fileUrl)
                            }
                        }
                    }
            }

            if !viewModel.uploadItemViewModels.isEmpty {
                Section("Upload progress") {
                    VStack {
                        ForEach(viewModel.uploadItemViewModels.indices, id: \.self) { index in
                            let viewModel = viewModel.uploadItemViewModels[index]
                            UploadItemView(viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .navigationTitle("Uploads")
    }
}
