//
//  DownloadRow.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 07.03.2023.
//

import SwiftUI

struct DownloadRow: View {
    @StateObject var viewModel: DownloadRowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .padding(.bottom, 8)
            
            Text("Status: \(viewModel.status)")
            Text("\(String(format: "%.1f", viewModel.percentCompleted))% of \(String(format: "%.1f", viewModel.totalMegaBytes))MB")
            
            if let errorTitle = viewModel.errorTitle {
                Text("Error: \(errorTitle)")
            }
            
            if let fileURL = viewModel.fileURL {
                Text("FileURL: \(fileURL)")
            }
            
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
        .padding(10)
        .background(
            Color.white
                .cornerRadius(15)
                .shadow(radius: 10)
        )
        .padding(15)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
