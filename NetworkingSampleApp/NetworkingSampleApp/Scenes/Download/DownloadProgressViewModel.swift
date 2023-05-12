//
//  DownloadRowViewModel.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 07.03.2023.
//

import SwiftUI
import Networking

final class DownloadProgressViewModel: ObservableObject {
    private let task: URLSessionTask
    
    @Published var state: DownloadProgressState = .init()
    
    init(task: URLSessionTask) {
        self.task = task
    }
    
    func onAppear() {
        Task {
            let stream = DownloadAPIManager.shared.progressStream(for: task)

            for try await downloadState in stream {
                DispatchQueue.main.async { [weak self] in
                    var newState = DownloadProgressState()
                    newState.percentCompleted = downloadState.fractionCompleted * 100
                    newState.totalMegaBytes = Double(downloadState.totalBytes) / 1_000_000
                    newState.status = downloadState.taskState
                    newState.statusTitle = downloadState.taskState.title
                    newState.errorTitle = downloadState.error?.localizedDescription
                    newState.fileURL = downloadState.downloadedFileURL?.absoluteString
                    newState.title = self?.task.currentRequest?.url?.absoluteString ?? "-"
                    self?.state = newState
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

// MARK: Download state
struct DownloadProgressState {
    var title: String = ""
    var status: URLSessionTask.State = .running
    var statusTitle: String = ""
    var percentCompleted: Double = 0
    var totalMegaBytes: Double = 0
    var errorTitle: String?
    var fileURL: String?
}

// MARK: URLSessionTask states
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
