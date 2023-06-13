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
                        button(
                            symbol: viewModel.isPaused ? "play" : "pause",
                            color: .blue,
                            action: { viewModel.isPaused ? viewModel.resume() : viewModel.pause() }
                        )

                        button(
                            symbol: "x",
                            color: .red,
                            action: { viewModel.cancel() }
                        )
                    }
                } else if viewModel.isRetryable {
                    button(
                        symbol: "repeat",
                        color: .blue,
                        action: { viewModel.retry() }
                    )
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

private extension UploadItemView {
    func button(symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                Image(systemName: symbol)
                    .symbolVariant(.circle.fill)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
            }
        )
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}
