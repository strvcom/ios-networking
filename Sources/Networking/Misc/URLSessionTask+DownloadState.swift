//
//  URLSessionTask+DownloadState.swift
//
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation

public extension URLSessionTask {
    /// A struct which provides you with information about a download, including bytes downloaded, total byte size of the file being downloaded or the error if any occurs.
    struct DownloadState {
        public var downloadedBytes: Int64
        public var totalBytes: Int64
        public var taskState: URLSessionTask.State
        public var error: Error?
        public var downloadedFileURL: URL?
        
        public var resumableData: Data? {
            (error as? URLError)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        }
        public var fractionCompleted: Double {
            guard totalBytes > 0 else {
                return 0
            }
            
            return Double(downloadedBytes)/Double(totalBytes)
        }
        
        public init(task: URLSessionTask) {
            downloadedBytes = task.countOfBytesReceived
            totalBytes = task.countOfBytesExpectedToReceive
            taskState = task.state
            error = task.error
            downloadedFileURL = nil
        }
    }
}
