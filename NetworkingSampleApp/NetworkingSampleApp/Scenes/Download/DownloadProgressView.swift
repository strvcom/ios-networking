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
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .task {
            await viewModel.startObservingDownloadProgress()
        }
        .padding(10)
        .background(
            Color.white
                .cornerRadius(15)
                .shadow(radius: 10)
        )
        .padding(15)
    }
}

// MARK: Components
private extension DownloadProgressView {
    @ViewBuilder
    var content: some View {
        Text(viewModel.state.title)
            .padding(.bottom, 8)
        
        Text("Status: \(viewModel.state.statusTitle)")
        Text("\(String(format: "%.1f", viewModel.state.percentCompleted))% of \(String(format: "%.1f", viewModel.state.totalMegaBytes))MB")
        
        if let errorTitle = viewModel.state.errorTitle {
            Text("Error: \(errorTitle)")
        }
        
        if let fileURL = viewModel.state.fileURL {
            Text("FileURL: \(fileURL)")
        }
        
        downloadState
    }
    
    @ViewBuilder
    var downloadState: some View {
        if viewModel.state.status != .completed {
            HStack {
                Button {
                    viewModel.suspend()
                } label: {
                    Text("Suspend")
                }
                
                Button {
                    viewModel.resume()
                } label: {
                    Text("Resume")
                }
                
                Button {
                    viewModel.cancel()
                } label: {
                    Text("Cancel")
                }
            }
        }
    }
}
