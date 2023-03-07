//
//  DownloadState.swift
//  
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation

public extension URLSessionTask {
    struct DownloadState {
        public var totalBytesWritten: Int64
        public var totalBytesExpectedToWrite: Int64
        public var taskState: URLSessionTask.State
        public var error: Error?
        public var downloadedFileURL: URL?
        
        public var resumableData: Data? {
            (error as? URLError)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        }
        public var fractionCompleted: Double {
            guard totalBytesExpectedToWrite > 0 else {
                return 0
            }
            
            return Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        }
        
        public init(task: URLSessionTask) {
            totalBytesWritten = task.countOfBytesReceived
            totalBytesExpectedToWrite = task.countOfBytesExpectedToReceive
            taskState = task.state
            error = task.error
            downloadedFileURL = nil
        }
    }
}
