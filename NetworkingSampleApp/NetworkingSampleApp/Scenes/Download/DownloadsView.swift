//
//  DownloadsView.swift
//
//
//  Created by Matej Molnár on 07.03.2023.
//

import SwiftUI
import Networking

struct DownloadsView: View {
    @StateObject private var viewModel = DownloadsViewModel()

    var body: some View {
        Form {
            Section(
                content: {
                    TextField("Download URL", text: $viewModel.urlText, axis: .vertical)
                },
                header: {
                    Text("URL")
                },
                footer: {
                    Button("Download") {
                        viewModel.startDownload()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            )

            if !viewModel.tasks.isEmpty {
                Section("Active downloads") {
                    List {
                        ForEach(viewModel.tasks, id: \.taskIdentifier) { task in
                            TaskProgressView(viewModel: DownloadProgressViewModel(task: task))
                        }
                    }
                }
            }
        }
        .navigationTitle("Downloads")
        .onAppear {
            viewModel.loadTasks()
        }
    }
}

#Preview {
    DownloadsView()
}
