//
//  DownloadRowViewModel.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 07.03.2023.
//

import SwiftUI
import Networking

class DownloadRowViewModel: ObservableObject {
    private let task: URLSessionTask
    
    @Published var title: String = ""
    @Published var status: String = ""
    @Published var percentCompleted: Double = 0
    @Published var totalMegaBytes: Double = 0
    @Published var errorTitle: String?
    @Published var fileURL: String?
    
    init(task: URLSessionTask) {
        self.task = task
        title = task.currentRequest?.url?.absoluteString ?? "-"
    }
    
    func onAppear() {
        Task {
            let stream = DownloadAPIManager.shared.progressStream(for: task)

            for try await downloadState in stream {
                DispatchQueue.main.async { [weak self] in
                    self?.percentCompleted = downloadState.fractionCompleted * 100
                    self?.totalMegaBytes = Double(downloadState.totalBytesExpectedToWrite) / 1000_000
                    self?.status = downloadState.taskState.title
                    self?.errorTitle = downloadState.error?.localizedDescription
                    self?.fileURL = downloadState.downloadedFileURL?.absoluteString
                }
            }
        }
    }
    
    func suspend() {
        task.suspend()
    }
    
    func resume() {
        task.resume()
    }
    
    func cancel() {
        task.cancel()
    }
}

private extension URLSessionTask.State {
    var title: String {
        switch self {
        case .canceling: return "cancelling"
        case .completed: return "completed"
        case .running: return "running"
        case .suspended: return "suspended"
        @unknown default: return ""
        }
    }
}
