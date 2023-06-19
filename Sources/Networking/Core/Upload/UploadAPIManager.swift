//
//  UploadAPIManager.swift
//  
//
//  Created by Tony Ngo on 12.06.2023.
//

import Combine
import Foundation

/// Default upload API manager
open class UploadAPIManager: NSObject {
    // MARK: - Public Properties
    public var allTasks: [UploadTask] {
        get async {
            let activeTasks = await urlSession.allTasks.compactMap { $0 as? URLSessionUploadTask }
            return await uploadTasks
                .getValues()
                .values
                // Values may contain inactive tasks
                .filter { activeTasks.contains($0.task) }
        }
    }

    // MARK: - Private Properties
    private var uploadTasks = ThreadSafeDictionary<String, UploadTask>()

    private lazy var urlSession = URLSession(
        configuration: urlSessionConfiguration,
        delegate: self,
        delegateQueue: nil
    )

    private let multiFormDataEncoder: MultiFormDataEncoding
    private let fileManager: FileManager
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let urlSessionConfiguration: URLSessionConfiguration
    private let sessionId: String

    // MARK: - Initialization
    public init(
        urlSessionConfiguration: URLSessionConfiguration = .default,
        multiFormDataEncoder: MultiFormDataEncoding = MultiFormDataEncoder(),
        fileManager: FileManager = .default,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.multiFormDataEncoder = multiFormDataEncoder
        self.fileManager = fileManager
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
        self.sessionId = Date.now.ISO8601Format()
        super.init()
    }
}

// MARK: - URLSessionTaskDelegate
extension UploadAPIManager: URLSessionTaskDelegate {
    public func urlSession(
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
}

// MARK: - UploadAPIManaging
extension UploadAPIManager: UploadAPIManaging {
    public func invalidateSession(shouldFinishTasks: Bool) {
        if shouldFinishTasks {
            urlSession.finishTasksAndInvalidate()
        } else {
            urlSession.invalidateAndCancel()
        }
    }

    public func upload(
        data: Data,
        to endpoint: Requestable,
        retryConfiguration: RetryConfiguration?
    ) async throws -> UploadTask {
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await uploadRequest(
            .data(data),
            request: endpointRequest,
            retryConfiguration: retryConfiguration
        )
    }

    public func upload(
        fromFile fileUrl: URL,
        to endpoint: Requestable,
        retryConfiguration: RetryConfiguration?
    ) async throws -> UploadTask {
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await uploadRequest(
            .file(fileUrl),
            request: endpointRequest,
            retryConfiguration: retryConfiguration
        )
    }

    public func upload(
        multiFormData: MultiFormData,
        sizeThreshold: UInt64 = 10_000_000,
        to endpoint: Requestable,
        retryConfiguration: RetryConfiguration?
    ) async throws -> UploadTask {
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)

        // Encode in-memory and upload directly if the payload's size is less than the threshold,
        // otherwise we write the payload to the disk first and upload by reading the file content.
        if multiFormData.size < sizeThreshold {
            let encodedMultiFormData = try multiFormDataEncoder.encode(multiFormData)
            return try await uploadRequest(
                .data(encodedMultiFormData),
                request: endpointRequest,
                retryConfiguration: retryConfiguration
            )
        } else {
            let temporaryFileUrl = try temporaryFileUrl(for: endpointRequest)
            try multiFormDataEncoder.encode(multiFormData, to: temporaryFileUrl)
            return try await uploadRequest(
                .file(temporaryFileUrl),
                request: endpointRequest,
                retryConfiguration: retryConfiguration
            )
        }
    }

    public func retry(
        taskId: String,
        retryConfiguration: RetryConfiguration?
    ) async throws {
        // Get stored upload task to invoke the request with the same arguments
        guard let existingUploadTask = await uploadTasks.getValue(for: taskId) else {
            throw NetworkError.unknown
        }

        // Removes the existing task from internal storage so that the `uploadRequest`
        // invocation treats the request/task as new
        await uploadTasks.set(value: nil, for: taskId)

        try await uploadRequest(
            existingUploadTask.uploadable,
            request: existingUploadTask.endpointRequest,
            retryConfiguration: retryConfiguration
        )
    }

    public func stateStream(for uploadTaskId: UploadTask.ID) async -> StateStream {
        let uploadTask = await uploadTasks
            .getValues()
            .values
            .first { $0.id == uploadTaskId }

        return uploadTask?.stateStream ?? Empty().eraseToAnyPublisher().values
    }
}

// MARK: - Private API
private extension UploadAPIManager {
    @discardableResult
    func uploadRequest(
        _ uploadable: Uploadable,
        request: EndpointRequest,
        retryConfiguration: RetryConfiguration?
    ) async throws -> UploadTask {
        do {
            let urlRequest = try await prepare(request)

            let sessionUploadTask = sessionUploadTask(
                with: uploadable,
                for: urlRequest
            ) { [weak self] data, response, error in
                self?.handleUploadTaskCompletion(
                    urlRequest: urlRequest,
                    endpointRequest: request,
                    retryConfiguration: retryConfiguration,
                    data: data,
                    response: response,
                    error: error
                )
            }

            let uploadTask = await existingUploadTaskOrNew(
                for: sessionUploadTask,
                request: request,
                uploadable: uploadable
            )

            // Store the task for future processing
            await uploadTasks.set(value: uploadTask, for: request.id)
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
    ) async -> UploadTask {
        guard var existingUploadTask = await uploadTasks.getValue(for: request.id) else {
            return UploadTask(
                sessionUploadTask: sessionUploadTask,
                endpointRequest: request,
                uploadable: uploadable,
                fileManager: fileManager
            )
        }
        existingUploadTask.task = sessionUploadTask
        return existingUploadTask
    }

    func handleUploadTaskCompletion(
        urlRequest: URLRequest,
        endpointRequest: EndpointRequest,
        retryConfiguration: RetryConfiguration?,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        Task {
            guard let uploadTask = await uploadTasks.getValue(for: endpointRequest.id) else {
                return
            }

            var state = UploadTask.State(task: uploadTask.task)
            if let data, let response {
                state.response = try await responseProcessors.process(
                    (data, response),
                    with: urlRequest,
                    for: endpointRequest
                )

                try await uploadTask.complete(with: state)

                // Cleanup on successful task completion
                await uploadTask.resetRetryCounter()
                await uploadTasks.set(value: nil, for: endpointRequest.id)
            } else if let error {
                do {
                    // URLError.Code.cancelled is thrown if the URLSessionTask is cancelled.
                    // Consider this action intentional, thus the request won't be retried.
                    guard !state.cancelled else {
                        throw error
                    }

                    try await uploadTask.sleepIfRetry(
                        for: error,
                        retryConfiguration: retryConfiguration
                    )

                    try await self.uploadRequest(
                        uploadTask.uploadable,
                        request: uploadTask.endpointRequest,
                        retryConfiguration: retryConfiguration
                    )
                } catch {
                    state.error = await errorProcessors.process(
                        error,
                        for: uploadTask.endpointRequest
                    )

                    // No cleanup in case the task will be retried.
                    try await uploadTask.complete(with: state)
                }
            }
        }
    }

    func sessionUploadTask(
        with uploadable: Uploadable,
        for request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionUploadTask {
        switch uploadable {
        case let .data(data):
            return urlSession.uploadTask(
                with: request,
                from: data,
                completionHandler: completionHandler
            )
        case let .file(fileUrl):
            return urlSession.uploadTask(
                with: request,
                fromFile: fileUrl,
                completionHandler: completionHandler
            )
        }
    }

    func prepare(_ request: EndpointRequest) async throws -> URLRequest {
        let originalRequest = try request.endpoint.asRequest()
        let adaptedRequest = try await requestAdapters.adapt(originalRequest, for: request)
        return adaptedRequest
    }

    func uploadTask(for task: URLSessionTask) async -> UploadTask? {
        await uploadTasks
            .getValues()
            .values
            .first { $0.taskIdentifier == task.taskIdentifier }
    }

    func temporaryFileUrl(for request: EndpointRequest) throws -> URL {
        let temporaryFileUrl = fileManager
            .temporaryDirectory
            .appendingPathComponent("ios-networking")
            .appendingPathComponent(request.id)
        try fileManager.createDirectory(at: temporaryFileUrl, withIntermediateDirectories: true)
        return temporaryFileUrl
    }
}
