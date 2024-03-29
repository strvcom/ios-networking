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
    @State var isFormFileImporterPresented = false
    @State var selectedPhotoPickerItem: PhotosPickerItem?

    var body: some View {
        Form {
            singleUpload
            multipartUpload

            if !viewModel.uploadTasks.isEmpty {
                Section("Active Uploads") {
                    VStack {
                        ForEach(viewModel.uploadTasks, id: \.id) { task in
                            TaskProgressView(viewModel: UploadProgressViewModel(task: task))
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
        .task {
            await viewModel.loadTasks()
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
                TextField("Enter username", text: $viewModel.formUsername)

                HStack {
                    if viewModel.formFileUrl == nil {
                        Button("Add attachment") { isFormFileImporterPresented = true }
                            .fileImporter(
                                isPresented: $isFormFileImporterPresented,
                                allowedContentTypes: [.mp3, .mpeg4Movie, .jpeg]
                            ) { result in
                                viewModel.formFileUrl = try? result.get()
                            }
                    }


                    Text(viewModel.formSelectedFileName)

                    Spacer()

                    if viewModel.formFileUrl != nil {
                        Button(
                            action: { viewModel.formFileUrl = nil },
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
                    viewModel.uploadForm()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        )
    }
}
