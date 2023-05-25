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
        VStack {
            HStack {
                TextField("File URL", text: $viewModel.urlText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    viewModel.startDownload()
                } label: {
                    Text("Download")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 15)
            
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.tasks, id: \.taskIdentifier) { task in
                        DownloadProgressView(viewModel: .init(task: task))
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("Downloads")
    }
}
