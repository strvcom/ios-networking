//
//  UploadsView.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import PhotosUI
import SwiftUI

struct UploadsView: View {
    @StateObject var viewModel = UploadsViewModel()

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
                        photo?.loadTransferable(type: Data.self) { result in
                            viewModel.uploadImage(result: result)
                        }
                    }

                Button("File") { isFileImporterPresented = true }
                    .fileImporter(
                        isPresented: $isFileImporterPresented,
                        allowedContentTypes: [.mp3, .mpeg4Movie]
                    ) { result in
                        viewModel.uploadFile(result: result)
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
