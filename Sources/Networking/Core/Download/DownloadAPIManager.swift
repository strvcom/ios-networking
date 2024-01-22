//
//  DownloadAPIManager.swift
//
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation
import Combine

/** Default download API manager which is responsible for the creation and management of network file downloads.

 You can define your own custom `DownloadAPIManager` if needed by conforming to ``DownloadAPIManaging``.

 The initialisation is equivalent to ``APIManager/init(urlSession:requestAdapters:responseProcessors:errorProcessors:)``, except the session is created for the user based on a given `URLSessionConfiguration` ``init(urlSessionConfiguration:requestAdapters:responseProcessors:errorProcessors:)``.

 ## Usage

 1. Request download for a given endpoint with ``downloadRequest(_:resumableData:retryConfiguration:)`` It creates a `URLSessionDownloadTask` and returns it along with ``Response``. The ``Response`` does not include the actual downloaded file, it solely an HTTP response received after the download is initiated.
 2. The ``allTasks`` property enables you to keep track of current tasks in progress.
 3. In order to observe progress of a specific task you can obtain an `AsyncStream` of ``Foundation/URLSessionTask/DownloadState`` with ``progressStream(for:)``.
 Example:
 ```swift
 for try await downloadState in downloadAPIManager.shared.progressStream(for: task) {
     ...
 }
 ```
 4. In case you are not using a singleton instance don't forget to call ``invalidateSession(shouldFinishTasks:)`` once the instance is not needed anymore in order to prevent memory leaks, since the `DownloadAPIManager` is not automatically deallocated from memory because of a `URLSession` holding a reference to it.
 */
open class DownloadAPIManager: NSObject, Retryable {
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let sessionId: String
    private let downloadStateDictSubject = CurrentValueSubject<[URLSessionTask: URLSessionTask.DownloadState], Never>([:])
    private var urlSession = URLSession(configuration: .default)
    private var taskStateCancellables = ThreadSafeDictionary<URLSessionTask, AnyCancellable>()
    private var downloadStateDict = ThreadSafeDictionary<URLSessionTask, URLSessionTask.DownloadState>()
    
    internal var retryCounter = Counter()
    
    public var allTasks: [URLSessionDownloadTask] {
        get async {
            await urlSession.allTasks.compactMap { $0 as? URLSessionDownloadTask }
        }
    }
    
    public init(
        urlSessionConfiguration: URLSessionConfiguration = .default,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        /// generate session id in readable format
        if #unavailable(iOS 15) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            sessionId = dateFormatter.string(from: Date())
        } else {
            sessionId = Date().ISO8601Format()
        }
        
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
                
        super.init()
        
        urlSession = URLSession(
            configuration: urlSessionConfiguration,
            delegate: self,
            delegateQueue: OperationQueue()
        )
    }
}

// MARK: Public API
extension DownloadAPIManager: DownloadAPIManaging {
    public func invalidateSession(shouldFinishTasks: Bool = false) {
        if shouldFinishTasks {
            urlSession.invalidateAndCancel()
        } else {
            urlSession.finishTasksAndInvalidate()
        }
    }
    
    public func downloadRequest(
        _ endpoint: Requestable,
        resumableData: Data? = nil,
        retryConfiguration: RetryConfiguration?
    ) async throws -> DownloadResult {
        /// create identifiable request from endpoint
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await downloadRequest(endpointRequest, resumableData: resumableData, retryConfiguration: retryConfiguration)
    }
    
    /// Creates an async stream of download state updates for a given task.
    /// Each time an update is received from the `URLSessionDownloadDelegate`, the async stream emits a new download state.
    public func progressStream(for task: URLSessionTask) -> AsyncStream<URLSessionTask.DownloadState> {
        AsyncStream { continuation in
            let cancellable = downloadStateDictSubject
                .sink(receiveValue: { dict in
                    guard let downloadState = dict[task] else {
                        return
                    }
                    
                    continuation.yield(downloadState)
                    
                    if downloadState.error != nil || downloadState.downloadedFileURL != nil {
                        continuation.finish()
                    }
                })
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

// MARK: Private
private extension DownloadAPIManager {
    func downloadRequest(
        _ endpointRequest: EndpointRequest,
        resumableData: Data?,
        retryConfiguration: RetryConfiguration?
    ) async throws -> DownloadResult {
        do {
            /// create original url request
            let originalRequest = try endpointRequest.endpoint.asRequest()
            
            /// adapt request with all adapters
            let request = try await requestAdapters.adapt(originalRequest, for: endpointRequest)
            
            /// create URLSessionDownloadTask with resumableData if available otherwise with URLRequest
            let downloadTask = {
                if let resumableData {
                    return urlSession.downloadTask(withResumeData: resumableData)
                } else {
                    return urlSession.downloadTask(with: request)
                }
            }()
            
            /// downloadTask must be initiated by resume() before we try to await a response from downloadObserver, because it gets the response from URLSessionDownloadDelegate methods
            downloadTask.resume()
            
            updateTasks()
            
            let urlResponse = try await downloadTask.asyncResponse()
            
            /// process response
            let response = try await responseProcessors.process((Data(), urlResponse), with: request, for: endpointRequest)
            
            /// reset retry count
            await retryCounter.reset(for: endpointRequest.id)
            
            /// create download AsyncStream
            return (downloadTask, response)
        } catch {
            do {
                /// If retry fails (retryCount is 0 or Task.sleep thrown), catch the error and process it with `ErrorProcessing` plugins.
                try await sleepIfRetry(
                    for: error,
                    endpointRequest: endpointRequest,
                    retryConfiguration: retryConfiguration
                )
                
                return try await downloadRequest(
                    endpointRequest,
                    resumableData: resumableData,
                    retryConfiguration: retryConfiguration
                )
            } catch {
                /// error processing
                throw await errorProcessors.process(error, for: endpointRequest)
            }
        }
    }
    
    /// Creates a record in the `downloadStateDict` for each task and observes their states.
    /// Every `downloadStateDict` update triggers an event to the `downloadStateDictSubject`
    /// which then leads to a task state update from `progressStream`.
    func updateTasks() {
        Task {
            for task in await allTasks where await downloadStateDict.getValue(for: task) == nil {
                /// In case there is no DownloadState for a given task in the dictionary, we need to create one.
                await downloadStateDict.set(value: .init(task: task), for: task)
                
                /// We need to observe URLSessionTask.State via KVO individually for each task, because there is no delegate callback for the state change.
                let cancellable = task
                    .publisher(for: \.state)
                    .sink { [weak self] state in
                        guard let self else {
                            return
                        }
                        
                        Task {
                            await self.downloadStateDict.update(task: task, for: \.taskState, with: state)
                            self.downloadStateDictSubject.send(await self.downloadStateDict.getValues())
                            
                            if state == .completed {
                                await self.taskStateCancellables.set(value: nil, for: task)
                            }
                        }
                    }
                
                await taskStateCancellables.set(value: cancellable, for: task)
            }
        }
    }
}

// MARK: URLSession Delegate
extension DownloadAPIManager: URLSessionDelegate, URLSessionDownloadDelegate {
    public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task {
            await downloadStateDict.update(task: downloadTask, for: \.downloadedBytes, with: totalBytesWritten)
            await downloadStateDict.update(task: downloadTask, for: \.totalBytes, with: totalBytesExpectedToWrite)
            downloadStateDictSubject.send(await downloadStateDict.getValues())
        }
    }
    
    public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let response = downloadTask.response else {
                return
            }
            
            // Move downloaded contents to documents as location will be unavailable after scope of this method.
            let tempURL = try location.moveContentsToDocuments(response: response)
            Task {
                await downloadStateDict.update(task: downloadTask, for: \.downloadedFileURL, with: tempURL)
                downloadStateDictSubject.send(await downloadStateDict.getValues())
                updateTasks()
            }
        } catch {
            Task {
                await downloadStateDict.update(task: downloadTask, for: \.error, with: error)
            }
        }
    }
    
    public func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task {
            await downloadStateDict.update(task: task, for: \.error, with: error)
            downloadStateDictSubject.send(await downloadStateDict.getValues())
            updateTasks()
        }
    }
}

extension URL {
    enum FileError: Error {
        case documentsDirectoryUnavailable
    }
    
    func moveContentsToDocuments(response: URLResponse) throws -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileError.documentsDirectoryUnavailable
        }
        
        // Use original filename.
        let filename = response.suggestedFilename ?? response.url?.lastPathComponent ?? lastPathComponent
        let newURL = documentsURL.appendingPathComponent(filename)
        
        try? FileManager.default.removeItem(at: newURL)
        try FileManager.default.moveItem(at: self, to: newURL)
        return newURL
    }
}
