//
//  UploadItemView.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import SwiftUI

struct UploadItemView: View {
    @ObservedObject var viewModel: UploadItemViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack {
                    Text(viewModel.fileName)
                        .font(.subheadline)
                    Text(viewModel.stateTitle)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Spacer()

                if !viewModel.isCancelled && !viewModel.isRetryable && !viewModel.isCompleted {
                    HStack {
                        TaskButton(config: viewModel.isPaused ? .play : .pause) {
                            viewModel.isPaused ? viewModel.resume() : viewModel.pause()
                        }

                        TaskButton(config: .cancel) {
                            viewModel.cancel()
                        }
                    }
                } else if viewModel.isRetryable {
                    TaskButton(config: .retry) {
                        viewModel.retry()
                    }
                }
            }

            if !viewModel.isCancelled && !viewModel.isRetryable {
                ProgressView(value: viewModel.progress, total: viewModel.totalProgress)
                    .progressViewStyle(.linear)
            }
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.progress)
        .padding(.vertical, 8)
        .task { await viewModel.observeProgress() }
    }
}
