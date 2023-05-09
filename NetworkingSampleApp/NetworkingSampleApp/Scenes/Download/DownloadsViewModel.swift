//
//  DownloadsViewModel.swift
//  
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation
import Networking
import OSLog

extension DownloadAPIManager {
    static var shared: DownloadAPIManager = {
        var responseProcessors: [ResponseProcessing] = [
            LoggingInterceptor.shared,
            StatusCodeProcessor.shared
        ]
        var errorProcessors: [ErrorProcessing] = [LoggingInterceptor.shared]
        
    #if DEBUG
        responseProcessors.append(EndpointRequestStorageProcessor.shared)
        errorProcessors.append(EndpointRequestStorageProcessor.shared)
    #endif
        
        return DownloadAPIManager(
            urlSessionConfiguration: .default,
            requestAdapters: [
                LoggingInterceptor.shared
            ],
            responseProcessors: responseProcessors,
            errorProcessors: errorProcessors
        )
    }()
}

@MainActor
final class DownloadsViewModel: ObservableObject {
    @Published var tasks: [URLSessionTask] = []
    @Published var urlText: String = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
    private let downloadAPIManager = DownloadAPIManager.shared
    
    func onAppear() {
        Task {
            tasks = await downloadAPIManager.allTasks
        }
    }
    
    func download() async {
        guard let url = URL(string: urlText) else {
            return
        }
        
        do {
            let (task, _) = try await downloadAPIManager.downloadRequest(
                SampleDownloadRouter.download(url: url),
                resumableData: nil,
                retryConfiguration: RetryConfiguration.default
            )
            
            tasks.append(task)
        } catch {
            os_log("❌ DownloadAPIManager failed to download \(self.urlText) with error: \(error.localizedDescription)")
        }
    }
}
