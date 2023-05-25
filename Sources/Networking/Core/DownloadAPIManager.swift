//
//  DownloadAPIManager.swift
//  
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation
import Combine

/// Default Download API manager
open class DownloadAPIManager: NSObject, Retryable {
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let sessionId: String
    private let downloadStateDictSubject = CurrentValueSubject<[URLSessionTask: URLSessionTask.DownloadState], Never>([:])
    private var urlSession: URLSession!
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
        sessionId = Date().ISO8601Format()
        
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
        
        super.init()
        
        urlSession = URLSession(
            configuration: urlSessionConfiguration,
            delegate: self,
            delegateQueue: OperationQueue()
        )
        
        Task {
            /// Publish initial download states value.
            downloadStateDictSubject.send(await downloadStateDict.getValues())
        }
    }
}

// MARK: Public API
extension DownloadAPIManager: DownloadAPIManaging {
    public func downloadRequest(
        _ endpoint: Requestable,
        resumableData: Data? = nil,
        retryConfiguration: RetryConfiguration?
    ) async throws -> DownloadResult {
        /// create identifiable request from endpoint
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await downloadRequest(endpointRequest, resumableData: resumableData, retryConfiguration: retryConfiguration)
    }
    
    /// Creates an async stream of download state updates for a given task. ]
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
        Task {
            await downloadStateDict.update(task: downloadTask, for: \.downloadedFileURL, with: location)
            downloadStateDictSubject.send(await downloadStateDict.getValues())
            updateTasks()
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
