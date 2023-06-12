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

    private var uploadTasks = ThreadSafeDictionary<String, UploadTask>()

    private lazy var urlSession = URLSession(
        configuration: urlSessionConfiguration,
        delegate: self,
        delegateQueue: nil
    )

    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let urlSessionConfiguration: URLSessionConfiguration
    private let sessionId: String

    public init(
        urlSessionConfiguration: URLSessionConfiguration = .default,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
        self.sessionId = Date.now.ISO8601Format()
        super.init()
    }
}

// MARK: - URLSessionDelegate, URLSessionTaskDelegate
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
        to endpoint: Requestable
    ) async throws -> UploadTask {
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await uploadRequest(.data(data), request: endpointRequest)
    }

    public func upload(
        fromFile fileUrl: URL,
        to endpoint: Requestable
    ) async throws -> UploadTask {
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await uploadRequest(.file(fileUrl), request: endpointRequest)
    }

    public func stateStream(for uploadTaskId: UploadTask.ID) async -> StateStream {
        let uploadTask = await uploadTasks
            .getValues()
            .values
            .first { $0.id == uploadTaskId }

        return uploadTask?.stateStream ?? Empty().eraseToAnyPublisher().values
    }
}

private extension UploadAPIManager {
    enum Uploadable {
        case data(Data)
        case file(URL)
    }

    func uploadRequest(
        _ uploadable: Uploadable,
        request: EndpointRequest
    ) async throws -> UploadTask {
        do {
            let urlRequest = try await prepare(request)

            let task = upload(
                uploadable,
                for: urlRequest
            ) { [uploadTasks, responseProcessors] data, response, error in
                Task {
                    guard let uploadTask = await uploadTasks.getValue(for: request.id) else {
                        return
                    }

                    var state = UploadTask.State(task: uploadTask.task)
                    if let data, let response {
                        state.response = try await responseProcessors.process(
                            (data, response),
                            with: urlRequest,
                            for: request
                        )
                    } else if let error {
                        state.error = error
                    }

                    uploadTask.statePublisher.send(state)
                }
            }

            let uploadTask = UploadTask(
                task: task,
                endpointRequest: request,
                statePublisher: .init(UploadTask.State(task: task))
            )

            // Store the task for future processing
            await uploadTasks.set(value: uploadTask, for: request.id)
            task.resume()
            return uploadTask
        } catch {
            do {
                return try await uploadRequest(uploadable, request: request)
            } catch {
                throw await errorProcessors.process(error, for: request)
            }
        }
    }

    func upload(
        _ uploadable: Uploadable,
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
}


