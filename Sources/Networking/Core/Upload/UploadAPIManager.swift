//
//  UploadAPIManager.swift
//
//
//  Created by Tony Ngo on 12.06.2023.
//

import Combine
import Foundation

/** Default upload API manager which is responsible for the creation and management of network file uploads.

 You can define your own custom `UploadAPIManager` if needed by conforming to ``UploadAPIManaging``.

 The initialisation is similar to ``APIManager/init(urlSession:requestAdapters:responseProcessors:errorProcessors:)``, except the session is created for the user based on a given `URLSessionConfiguration` + you can also inject ``MultipartFormDataEncoding`` and `FileManager`  ``init(urlSessionConfiguration:multipartFormDataEncoder:fileManager:requestAdapters:responseProcessors:errorProcessors:)``.

 ## Usage

 1. Start a download by calling the ``upload(_:to:)`` function and passing ``UploadType`` which defines three types of possible resources for upload `Data`, file `URL` and ``MultipartFormData``. It returns an `UploadTask`, which is a struct that under the hood represents + manages a URLSessionUploadTask and provides its state.
 2. The ``activeTasks`` property enables you to keep track of current tasks in progress.
 3. In order to observe progress of a specific task you can obtain a ``UploadAPIManaging/StateStream`` which is an `AsyncPublisher` of ``UploadTask/State`` with ``stateStream(for:)``.

 ```swift
 for await uploadState in await uploadManager.stateStream(for: task.id) {
 ...
 }
 ```
 4. You can retry a specific task in case of failure with ``retry(taskId:)``
 5. In case you are not using a singleton instance don't forget to call ``invalidateSession(shouldFinishTasks:)`` once the instance is not needed anymore in order to prevent memory leaks, since the `UploadAPIManager` is not automatically deallocated from memory because of a `URLSession` holding a reference to it.
 */
@available(iOS 15.0, *)
open class UploadAPIManager: NSObject, UploadAPIManaging {
    // MARK: - Public Properties
    public var activeTasks: [UploadTask] {
        get async {
            let activeTasks = await urlSession.allTasks.compactMap { $0 as? URLSessionUploadTask }
            // Values may contain inactive tasks
            return uploadTasks.values.filter { activeTasks.contains($0.task) }
        }
    }

    // MARK: - Private Properties
    private var uploadTasks = [String: UploadTask]()

    private lazy var urlSession = URLSession(
        configuration: urlSessionConfiguration,
        delegate: self,
        delegateQueue: nil
    )

    private let multipartFormDataEncoder: MultipartFormDataEncoding
    private let fileManager: FileManager
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let urlSessionConfiguration: URLSessionConfiguration
    private let sessionId: String

    // MARK: - Initialization
    public init(
        urlSessionConfiguration: URLSessionConfiguration = .default,
        multipartFormDataEncoder: MultipartFormDataEncoding = MultipartFormDataEncoder(),
        fileManager: FileManager = .default,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.multipartFormDataEncoder = multipartFormDataEncoder
        self.fileManager = fileManager
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
        self.sessionId = Date.now.ISO8601Format()
        super.init()
    }
}

// MARK: URLSessionDataDelegate
@available(iOS 15.0, *)
extension UploadAPIManager: URLSessionDataDelegate {
    nonisolated public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        Task {
            guard let uploadTask = await uploadTask(for: dataTask) else {
                return
            }
            
            if let originalRequest = dataTask.originalRequest,
               let response = dataTask.response {
                do {
                    try await handleUploadTaskCompletion(
                        uploadTask: uploadTask,
                        urlRequest: originalRequest,
                        response: response,
                        data: data
                    )
                } catch {
                    await handleUploadTaskError(
                        uploadTask: uploadTask,
                        error: error
                    )
                }
            }
        }
    }
}

// MARK: - URLSessionTaskDelegate
@available(iOS 15.0, *)
extension UploadAPIManager: URLSessionTaskDelegate {
    nonisolated public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        Task {
            await uploadTask(for: task)?
                .statePublisher
                .send(UploadTask.State(task: task))
        }
    }
        
    nonisolated public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        Task {
            await uploadTask(for: task)?
                .statePublisher
                .send(UploadTask.State(task: task))

            guard let uploadTask = await uploadTask(for: task) else {
                return
            }
                        
            await handleUploadTaskError(
                uploadTask: uploadTask,
                error: error
            )
        }
    }
}

// MARK: - UploadAPIManaging
@available(iOS 15.0, *)
extension UploadAPIManager: UploadAPIManaging {
    public func upload(_ type: UploadType, to endpoint: Requestable) async throws -> UploadTask {
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)

        switch type {
        case let .data(data, _):
            return try await uploadRequest(
                .data(data),
                request: endpointRequest
            )
        case let .file(fileUrl):
            return try await uploadRequest(
                .file(fileUrl),
                request: endpointRequest
            )
        case let .multipart(multipartFormData, sizeThreshold):
            // Determine if the session configuration is background.
            let usesBackgroundSession = urlSessionConfiguration.sessionSendsLaunchEvents

            // Encode in-memory and upload directly if the payload's size is less than the threshold,
            // otherwise we write the payload to the disk first and upload by reading the file content.
            if multipartFormData.size < sizeThreshold && !usesBackgroundSession {
                let encodedMultipartFormData = try multipartFormDataEncoder.encode(multipartFormData)
                return try await uploadRequest(
                    .data(encodedMultipartFormData),
                    request: endpointRequest
                )
            } else {
                let temporaryFileUrl = try temporaryFileUrl(for: endpointRequest)
                try multipartFormDataEncoder.encode(multipartFormData, to: temporaryFileUrl)
                return try await uploadRequest(
                    .file(temporaryFileUrl, removeOnComplete: true),
                    request: endpointRequest
                )
            }
        }
    }
    
    public func invalidateSession(shouldFinishTasks: Bool) {
        if shouldFinishTasks {
            urlSession.finishTasksAndInvalidate()
        } else {
            urlSession.invalidateAndCancel()
        }
    }

    public func retry(taskId: String) async throws {
        // Get stored upload task to invoke the request with the same arguments
        guard let existingUploadTask = uploadTasks[taskId] else {
            throw NetworkError.unknown
        }

        // Removes the existing task from internal storage so that the `uploadRequest`
        // invocation treats the request/task as new
        uploadTasks[taskId] = nil

        try await uploadRequest(
            existingUploadTask.uploadable,
            request: existingUploadTask.endpointRequest
        )
    }

    public func stateStream(for uploadTaskId: UploadTask.ID) -> StateStream {
        let uploadTask = uploadTasks.values.first { $0.id == uploadTaskId }

        return uploadTask?.stateStream ?? Empty().eraseToAnyPublisher().values
    }
}

// MARK: - Private API
@available(iOS 15.0, *)
private extension UploadAPIManager {
    @discardableResult
    func uploadRequest(
        _ uploadable: Uploadable,
        request: EndpointRequest
    ) async throws -> UploadTask {
        do {
            let urlRequest = try await prepare(request)
            
            let sessionUploadTask = sessionUploadTask(
                with: uploadable,
                for: urlRequest
            )
            
            let uploadTask = existingUploadTaskOrNew(
                for: sessionUploadTask,
                request: request,
                uploadable: uploadable
            )
            
            // Store the task for future processing
            uploadTasks[request.id] = uploadTask
            sessionUploadTask.resume()

            return uploadTask
        } catch {
            throw await errorProcessors.process(error, for: request)
        }
    }

    /// Returns any stored upload task and updates its internal URLSessionUploadTask, or creates a new one.
    func existingUploadTaskOrNew(
        for sessionUploadTask: URLSessionUploadTask,
        request: EndpointRequest,
        uploadable: Uploadable
    ) -> UploadTask {
        guard var existingUploadTask = uploadTasks[request.id] else {
            return UploadTask(
                sessionUploadTask: sessionUploadTask,
                endpointRequest: request,
                uploadable: uploadable
            )
        }
        existingUploadTask.task = sessionUploadTask
        return existingUploadTask
    }

    func handleUploadTaskCompletion(
        uploadTask: UploadTask,
        urlRequest: URLRequest,
        response: URLResponse,
        data: Data
    ) async throws {
        var state = UploadTask.State(task: uploadTask.task)
        state.response = try await responseProcessors.process(
            (data, response),
            with: urlRequest,
            for: uploadTask.endpointRequest
        )
        await uploadTask.complete(with: state)
        
        // Cleanup on successful task completion
        await uploadTask.cleanup()
        uploadTasks[uploadTask.endpointRequest.id] = nil
    }
    
    func handleUploadTaskError(
        uploadTask: UploadTask,
        error: Error?
    ) async {
        var state = UploadTask.State(task: uploadTask.task)
        
        if let error {
            // URLError.Code.cancelled is thrown if the URLSessionTask is cancelled.
            // Consider this action intentional, thus the request won't be retried.
            guard !state.cancelled else {
                return
            }
            
            state.error = await errorProcessors.process(
                error,
                for: uploadTask.endpointRequest
            )
            
            // No cleanup in case the task will be retried.
            await uploadTask.complete(with: state)
        }
    }

    /// The implementation uses completion closure version of the upload task instaed of the async versions.
    ///
    /// The async versions could be used, however, if we go down that route, we'll need to make some slight
    /// changes to the implementation, because:
    /// - The async versions don't return `URLSessionTask` and will be suspended, which means returning immediately
    ///   as it is now wouldn't be possible. So we'll need to consider what to return to the client, if anything at all.
    /// - We'll need to handle errors and responses from the request using delegates.
    func sessionUploadTask(
        with uploadable: Uploadable,
        for request: URLRequest
    ) -> URLSessionUploadTask {
        switch uploadable {
        case let .data(data):
            return urlSession.uploadTask(
                with: request,
                from: data
            )
        case let .file(fileUrl, _):
            return urlSession.uploadTask(
                with: request,
                fromFile: fileUrl
            )
        }
    }

    func prepare(_ request: EndpointRequest) async throws -> URLRequest {
        let originalRequest = try request.endpoint.asRequest()
        let adaptedRequest = try await requestAdapters.adapt(originalRequest, for: request)
        return adaptedRequest
    }

    func uploadTask(for task: URLSessionTask) -> UploadTask? {
        uploadTasks.values.first { $0.taskIdentifier == task.taskIdentifier }
    }

    func temporaryFileUrl(for request: EndpointRequest) throws -> URL {
        let temporaryDirectoryUrl = fileManager
            .temporaryDirectory
            .appendingPathComponent("ios-networking")

        let temporaryFileUrl = temporaryDirectoryUrl
            .appendingPathComponent(request.id)
        try fileManager.createDirectory(at: temporaryDirectoryUrl, withIntermediateDirectories: true)
        return temporaryFileUrl
    }
}
