//
//  APIManager.swift
//  
//
//  Created by Matej Molnár on 24.11.2022.
//

import Foundation

/// Default API manager
open class APIManager: APIManaging {
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let responseProvider: ResponseProviding
    private let sessionId: String
    private var retryCounter = Counter()
    
    public init(
        urlSession: URLSession = .init(configuration: .default),
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor()],
        errorProcessors: [ErrorProcessing] = []
    ) {
        /// generate session id in readable format
        sessionId = Date().ISO8601Format()
        self.responseProvider = urlSession
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
    }
    
    public init(
        responseProvider: ResponseProviding,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor()],
        errorProcessors: [ErrorProcessing] = []
    ) {
        /// generate session id in readable format
        sessionId = Date().ISO8601Format()
        self.responseProvider = responseProvider
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
    }
    
    @discardableResult
    open func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response {
        /// create identifiable request from endpoint
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await request(endpointRequest, retryConfiguration: retryConfiguration)
    }
    
    @discardableResult
    open func downloadStream(
        _ endpoint: Requestable,
        resumableData: Data? = nil,
        retryConfiguration: RetryConfiguration?
    ) async throws -> AsyncThrowingStream<DownloadState, Error> {
        /// create identifiable request from endpoint
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await downloadStream(endpointRequest, resumableData: resumableData, retryConfiguration: retryConfiguration)
    }
}

private extension APIManager {
    func downloadStream(
        _ endpointRequest: EndpointRequest,
        resumableData: Data?,
        retryConfiguration: RetryConfiguration?
    ) async throws -> AsyncThrowingStream<DownloadState, Error> {
        do {
            /// create original url request
            let originalRequest = try endpointRequest.endpoint.asRequest()
            
            /// adapt request with all adapters
            let request = try await requestAdapters.adapt(originalRequest, for: endpointRequest)

            /// create URLSessionDownloadTask with resumableData if available otherwise with URLRequest
            let downloadTask = {
                if let resumableData {
                    return URLSession.shared.downloadTask(withResumeData: resumableData)
                } else {
                    return URLSession.shared.downloadTask(with: request)
                }
            }()
            
            /// create a DownloadObserver which implements URLSessionDownloadDelegate methods and assign it as delegate
            let downloadObserver = DownloadObserver()
            downloadTask.delegate = downloadObserver
            
            /// downloadTask must be initiated by resume() before we try to await a response from downloadObserver, because it gets the response from URLSessionDownloadDelegate methods
            downloadTask.resume()
            
            let response = try await downloadObserver.response()
            
            do {
                /// process response. Since we are not returning the response, we don't need to keep reference to it.
                _ = try await responseProcessors.process((Data(), response), with: request, for: endpointRequest)
            } catch {
                /// in case response processing fails we need to manually cancel also the downloadTask otherwise it would just continue running.
                downloadTask.cancel()
                throw error
            }
            
            /// reset retry count
            await retryCounter.reset(for: endpointRequest.id)
            
            /// create download AsyncStream
            return downloadStream(for: endpointRequest, downloadTask: downloadTask, downloadObserver: downloadObserver)
        } catch {
            do {
                /// If retry fails (retryCount is 0 or Task.sleep thrown), catch the error and process it with `ErrorProcessing` plugins.
                try await sleepIfRetry(for: error, endpointRequest: endpointRequest, retryConfiguration: retryConfiguration)
            } catch {
                /// error processing
                throw await errorProcessors.process(error, for: endpointRequest)
            }
            
            return try await downloadStream(endpointRequest, resumableData: resumableData, retryConfiguration: retryConfiguration)
        }
    }
    
    func downloadStream(
        for endpointRequest: EndpointRequest,
        downloadTask: URLSessionDownloadTask,
        downloadObserver: DownloadObserver
    ) -> AsyncThrowingStream<DownloadState, Error>  {
        return AsyncThrowingStream { continuation in
            downloadObserver.progressHandler = { (downloaded, total) in
                continuation.yield(.progress(downloadedBytes: Double(downloaded), totalBytes: Double(total)))
            }

            downloadObserver.completionHandler = { data in
                continuation.yield(.completed(data))
                continuation.finish()
            }
            
            downloadObserver.errorHandler = { [errorProcessors] error in
                if let resumableData = (error as? URLError)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    continuation.yield(.terminated(resumableData: resumableData))
                }
                
                Task {
                    /// error processing
                    let error = await errorProcessors.process(error, for: endpointRequest)
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { _ in
                /// this handler is invoked in case this async stream gets wrapped in a task and the task gets cancelled. When this happens we need to manually cancel also the downloadTask otherwise it would just continue running.
                downloadTask.cancel()
            }
        }
    }
    
    func request(_ endpointRequest: EndpointRequest, retryConfiguration: RetryConfiguration?) async throws -> Response {
        do {
            /// create original url request
            var request = try endpointRequest.endpoint.asRequest()
            
            /// adapt request with all adapters
            request = try await requestAdapters.adapt(request, for: endpointRequest)

            /// get response for given request (usually fires a network request via URLSession)
            var response = try await responseProvider.response(for: request)
            
            /// process request
            response = try await responseProcessors.process(response, with: request, for: endpointRequest)
            
            /// reset retry count
            await retryCounter.reset(for: endpointRequest.id)
            
            return response
        } catch {
            do {
                /// If retry fails (retryCount is 0 or Task.sleep thrown), catch the error and process it with `ErrorProcessing` plugins.
                try await sleepIfRetry(for: error, endpointRequest: endpointRequest, retryConfiguration: retryConfiguration)
            } catch {
                /// error processing
                throw await errorProcessors.process(error, for: endpointRequest)
            }
            
            return try await request(endpointRequest, retryConfiguration: retryConfiguration)
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
