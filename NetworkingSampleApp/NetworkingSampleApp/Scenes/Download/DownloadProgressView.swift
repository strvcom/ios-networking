//
//  DownloadProgressView.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 07.03.2023.
//

import SwiftUI

struct DownloadProgressView: View {
    @StateObject var viewModel: DownloadProgressViewModel
    
    var body: some View {
        content
            .task {
                await viewModel.startObservingDownloadProgress()
            }
    }
}

// MARK: Components
private extension DownloadProgressView {
    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.state.title)
                .truncationMode(.middle)
                .lineLimit(1)
                .padding(.bottom, 8)
            
            Group {
                if let errorTitle = viewModel.state.errorTitle {
                    Text("Error: \(errorTitle)")
                } else {
                    Text("Status: \(viewModel.state.statusTitle)")
                }
                
                if let fileURL = viewModel.state.fileURL {
                    Text("FileURL: \(fileURL)")
                }

                HStack {
                    ProgressView(value: viewModel.state.percentCompleted, total: 100)
                        .progressViewStyle(.linear)
                        .frame(width: 150)

                    Text("\(String(format: "%.1f", viewModel.state.megaBytesCompleted))MB")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    Spacer()

                    TaskButton(config: viewModel.state.status == .suspended ? .play : .pause) {
                        viewModel.state.status == .suspended ? viewModel.resume() : viewModel.suspend()
                    }

                    TaskButton(config: .cancel) {
                        viewModel.cancel()
                    }
                }
            }
            .font(.footnote)
            .foregroundColor(.gray)
        }
    }
}
