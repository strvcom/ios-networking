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
    @StateObject var formViewModel = FormUploadsViewModel()

    @State var isPhotosPickerPresented = false
    @State var isFileImporterPresented = false
    @State var isFormFileImporterPresented = false
    @State var selectedPhotoPickerItem: PhotosPickerItem?

    var body: some View {
        Form {
            singleUpload

            if !viewModel.uploadItemViewModels.isEmpty {
                Section("Single upload progress") {
                    VStack {
                        ForEach(viewModel.uploadItemViewModels.indices, id: \.self) { index in
                            let viewModel = viewModel.uploadItemViewModels[index]
                            UploadItemView(viewModel: viewModel)
                        }
                    }
                }
            }

            multipartUpload

            if !formViewModel.uploadItemViewModels.isEmpty {
                Section("Multi part upload progress") {
                    VStack {
                        ForEach(formViewModel.uploadItemViewModels.indices, id: \.self) { index in
                            let viewModel = formViewModel.uploadItemViewModels[index]
                            UploadItemView(viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .alert(
            "Error",
            isPresented: $viewModel.isErrorAlertPresented,
            actions: {},
            message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        )
        .alert(
            "Error",
            isPresented: $formViewModel.isErrorAlertPresented,
            actions: {},
            message: {
                Text(formViewModel.error?.localizedDescription ?? "")
            }
        )
        .navigationTitle("Uploads")
    }
}

private extension UploadsView {
    var singleUpload: some View {
        Section("Single") {
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
    }

    var multipartUpload: some View {
        Section(
            content: {
                TextField("Enter username", text: $formViewModel.username)

                HStack {
                    if formViewModel.fileUrl == nil {
                        Button("Add attachment") { isFormFileImporterPresented = true }
                            .fileImporter(
                                isPresented: $isFormFileImporterPresented,
                                allowedContentTypes: [.mp3, .mpeg4Movie]
                            ) { result in
                                formViewModel.fileUrl = try? result.get()
                            }
                    }


                    Text(formViewModel.selectedFileName)

                    Spacer()

                    if formViewModel.fileUrl != nil {
                        Button(
                            action: { formViewModel.fileUrl = nil },
                            label: {
                                Image(systemName: "x")
                                    .symbolVariant(.circle.fill)
                                    .font(.title2)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.tertiary)
                            }
                        )
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                    }
                }
            },
            header: {
                Text("Multipart")
            },
            footer: {
                Button("Upload") {
                    formViewModel.uploadForm()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        )
    }
}
