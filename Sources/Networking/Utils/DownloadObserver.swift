//
//  DownloadObserver.swift
//  
//
//  Created by Matej Molnár on 16.01.2023.
//

import Foundation

enum DownloadObserverError: Error {
    case missingResponse
}

open class DownloadObserver: NSObject {
    public var progressHandler: ((_ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> ())?
    public var errorHandler: ((Error) -> ())?
    public var completionHandler: ((Data?) -> ())?
    
    private var responseHandler: ((URLResponse?, Error?) -> ())?
    private var isResponseHandled = false
}

extension DownloadObserver {
    func response() async throws -> URLResponse {
        return try await withCheckedThrowingContinuation({ continuation in
            responseHandler = { (response, error) in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let response {
                    continuation.resume(returning: response)
                    return
                }
                
                continuation.resume(throwing: DownloadObserverError.missingResponse)
            }
        })
    }
}

extension DownloadObserver: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        responseHandler?(downloadTask.response, nil)
        responseHandler = nil
        
        progressHandler?(totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        responseHandler?(downloadTask.response, nil)
        responseHandler = nil
        
        completionHandler?(try? Data(contentsOf: location))
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        responseHandler?(task.response, error)
        responseHandler = nil
        
        if let error {
            errorHandler?(error)
        }
    }
}
