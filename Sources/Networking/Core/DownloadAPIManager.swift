//
//  DownloadAPIManager.swift
//  
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation
import Combine

/// Default Download API manager
open class DownloadAPIManager: NSObject {
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private var urlSession: URLSession!
    private let sessionId: String
    private var retryCounter = Counter()
    private var taskStateCancellables: [URLSessionTask: AnyCancellable] = [:]
    private let downloadStateDictSubject = CurrentValueSubject<[URLSessionTask: URLSessionTask.DownloadState], Never>([:])
    private var downloadStateDict = [URLSessionTask: URLSessionTask.DownloadState]() {
        didSet {
            downloadStateDictSubject.send(downloadStateDict)
        }
    }
    
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
    }
    
    public func downloadRequest(
        _ endpoint: Requestable,
        resumableData: Data? = nil,
        retryConfiguration: RetryConfiguration?
    ) async throws -> (URLSessionDownloadTask, Response) {
        /// create identifiable request from endpoint
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await downloadRequest(endpointRequest, resumableData: resumableData, retryConfiguration: retryConfiguration)
    }
    
    public func progressStream(for task: URLSessionTask) -> AsyncStream<URLSessionTask.DownloadState> {
        AsyncStream { continuation in
            let cancellable = downloadStateDictSubject
                .sink(receiveValue: { dict in
                    guard let downloadState = dict[task] else {
                        return
                    }
                    
                    continuation.yield(downloadState)
                    
                    if
                        downloadState.error != nil ||
                        downloadState.downloadedFileURL != nil
                    {
                        continuation.finish()
                    }
                })
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

private extension DownloadAPIManager {
    func downloadRequest(
         _ endpointRequest: EndpointRequest,
         resumableData: Data?,
         retryConfiguration: RetryConfiguration?
     ) async throws -> (URLSessionDownloadTask, Response) {
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
                 try await sleepIfRetry(for: error, endpointRequest: endpointRequest, retryConfiguration: retryConfiguration)
                 
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

    func updateTasks() {
        Task {
            for task in await allTasks where downloadStateDict[task] == nil {
                /// In case there is no DownloadState for a given task in the dictionary, we need to create one.
                downloadStateDict[task] = .init(task: task)
                
                /// We need to observe URLSessionTask.State via KVO individually for each task, because there is no delegate callback for the state change.
                taskStateCancellables[task] = task
                    .publisher(for: \.state)
                    .sink { [weak self] state in
                        self?.downloadStateDict[task]?.taskState = state
                        
                        if state == .completed {
                            self?.taskStateCancellables[task] = nil
                        }
                    }
            }
        }
    }
    
    /// Handle if error triggers retry mechanism and return delay for next attempt
    private func sleepIfRetry(for error: Error, endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) async throws {
        let retryCount = await retryCounter.count(for: endpointRequest.id)
        
        guard
            let retryConfiguration = retryConfiguration,
            retryConfiguration.retryHandler(error),
            retryConfiguration.retries > retryCount
        else {
            /// reset retry count
            await retryCounter.reset(for: endpointRequest.id)
            throw error
        }
                
        /// count the delay for retry
        await retryCounter.increment(for: endpointRequest.id)
        
        var sleepDuration: UInt64
        switch retryConfiguration.delay {
        case .constant(let timeInterval):
            sleepDuration = UInt64(timeInterval) * 1000000000
        case .progressive(let timeInterval):
            sleepDuration = UInt64(timeInterval) * UInt64(retryCount) * 1000000000
        }
        
        try await Task.sleep(nanoseconds: sleepDuration)
    }
}

extension DownloadAPIManager: URLSessionDelegate, URLSessionDownloadDelegate {
    public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        downloadStateDict[downloadTask]?.totalBytesWritten = totalBytesWritten
        downloadStateDict[downloadTask]?.totalBytesExpectedToWrite = totalBytesExpectedToWrite
    }

    public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        downloadStateDict[downloadTask]?.downloadedFileURL = location
        updateTasks()
    }

    public func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        downloadStateDict[task]?.error = error
        updateTasks()
    }
}

private extension URLSessionTask {
    func asyncResponse() async throws -> URLResponse {
        var cancellable: AnyCancellable?
        
        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    cancellable = Publishers.CombineLatest(
                        publisher(for: \.response),
                        publisher(for: \.error)
                    )
                    .first(where: { (response, error) in
                        response != nil || error != nil
                    })
                    .sink { (response, error) in
                        if let error {
                            continuation.resume(throwing: error)
                        }
                        
                        if let response {
                            continuation.resume(returning: response)
                        }
                    }
                }
            },
            onCancel: { [cancellable] in
                cancellable?.cancel()
            })
    }
}
