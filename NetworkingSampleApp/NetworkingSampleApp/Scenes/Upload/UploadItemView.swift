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
                    Text(viewModel.isCancelled ? "Cancelled" : viewModel.formattedProgress)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Spacer()

                if !viewModel.isCancelled && !viewModel.isRetryable {
                    HStack {
                        Button(action: {
                            viewModel.isPaused ? viewModel.resume() : viewModel.pause()
                        }, label: {
                            Image(systemName: viewModel.isPaused ? "play" : "pause")
                                .symbolVariant(.circle.fill)
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue)
                        })
                        .buttonStyle(.plain)
                        .contentShape(Circle())

                        Button(action: {
                            viewModel.cancel()
                        }, label: {
                            Image(systemName: "x")
                                .symbolVariant(.circle.fill)
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.red)
                        })
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                    }
                } else if viewModel.isRetryable {
                    Button(action: {
                        // TODO: Allow retry
                    }, label: {
                        Image(systemName: "repeat")
                            .symbolVariant(.circle.fill)
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    })
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
            }

            if !viewModel.isCancelled {
                ProgressView(value: viewModel.progress, total: viewModel.totalProgress)
                    .progressViewStyle(.linear)
            }
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.progress)
        .padding(.vertical, 8)
        .task { await viewModel.observeProgress() }
    }
}
