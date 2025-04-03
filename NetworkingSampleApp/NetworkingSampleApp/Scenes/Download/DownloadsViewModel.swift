//
//  DownloadsViewModel.swift
//
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation
import Networking
import OSLog

@MainActor
final class DownloadsViewModel: ObservableObject {
    @Published var tasks: [URLSessionTask] = []
    @Published var urlText: String = SampleAPIConstants.videoUrl

    @NetworkingActor
    private lazy var downloadAPIManager = DownloadAPIManager.shared

    func startDownload() {
        Task {
            await downloadItem()
        }
    }

    func loadTasks() {
        Task {
            tasks = await downloadAPIManager.allTasks
        }
    }
}

private extension DownloadsViewModel {
    func downloadItem() async {
        guard let url = URL(string: urlText) else {
            return
        }
        
        do {
            let (task, _) = try await downloadAPIManager.downloadRequest(
                url,
                resumableData: nil,
                retryConfiguration: RetryConfiguration.default
            )
            
            tasks.append(task)
        } catch {
            os_log("❌ DownloadAPIManager failed to download \(self.urlText) with error: \(error.localizedDescription)")
        }
    }
}
