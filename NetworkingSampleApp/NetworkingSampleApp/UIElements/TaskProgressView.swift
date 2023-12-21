//
//  TaskProgressView.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 21.12.2023.
//

import SwiftUI

@MainActor
protocol TaskProgressViewModel: ObservableObject {
    var title: String { get }
    var status: String { get }
    var downloadedBytes: String { get }
    var state: URLSessionTask.State { get }
    var percentCompleted: Double { get }
    var isRetryable: Bool { get }

    func suspend()
    func resume()
    func cancel()
    func retry()
    func onAppear()
}

struct TaskProgressView<ViewModel: TaskProgressViewModel>: View {
    @StateObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .truncationMode(.middle)
                .lineLimit(1)
                .padding(.bottom, 8)

            Text(viewModel.status)
                .font(.footnote)
                .foregroundColor(.gray)

            HStack {
                ProgressView(value: viewModel.percentCompleted, total: 100)
                    .progressViewStyle(.linear)
                    .frame(width: 150)

                Text(viewModel.downloadedBytes)
                    .font(.footnote)
                    .foregroundColor(.gray)

                Spacer()

                if viewModel.state != .completed {
                    TaskButton(config: viewModel.state == .suspended ? .play : .pause) {
                        viewModel.state == .suspended ? viewModel.resume() : viewModel.suspend()
                    }

                    TaskButton(config: .cancel) {
                        viewModel.cancel()
                    }
                } else if viewModel.isRetryable {
                    TaskButton(config: .retry) {
                        viewModel.retry()
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
