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
    @ObservedObject var formViewModel: FormUploadsViewModel
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
    }

    var multipartUpload: some View {
        Section(
            content: {
                TextField("Enter text", text: $formViewModel.text)

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