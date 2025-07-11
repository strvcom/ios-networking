//
//  APIManager.swift
//
//
//  Created by Matej Molnár on 24.11.2022.
//

import Foundation

/** Default API manager which is responsible for the creation and management of network requests.

 You can define your own custom `APIManager` if needed by conforming to ``APIManaging``.

 ## Initialisation
 There are two ways to initialise the `APIManager` object:
 1. ``init(urlSession:requestAdapters:responseProcessors:errorProcessors:)`` - uses a `URLSession` as the response provider (typical usage).
 2. ``init(responseProvider:requestAdapters:responseProcessors:errorProcessors:)`` - uses a custom response provider by conforming to ``ResponseProviding``. An example of a custom provider is ``MockResponseProvider``, which can be used for UI tests to interact with mocked data saved through ``EndpointRequestStorageProcessor``. To utilise them, simply move the stored session folder into the Asset catalogue.

 ## Making requests
 There are two methods for making requests provided by the ``APIManaging`` protocol:
 1. ``request(_:retryConfiguration:)-1usms`` - ``Response`` is a typealias for URLSession's default (data, response) tuple.
 2. ``request(_:decoder:retryConfiguration:)`` - Result is custom decodable object
 
 ```swift
 let userResponse: UserResponse = try await apiManager.request(UserRouter.getUser)
 ```

 ## Retry-ability
 You can provide a custom after failure ``RetryConfiguration``, specifying the count of retries, delay and a handler that determines whether the request should be tried again. Otherwise, ``RetryConfiguration/default`` configuration is used.

 ```swift
 let retryConfiguration = RetryConfiguration(retries: 2, delay: .constant(1)) { error in
     // custom logic here
 }
 let userResponse: UserResponse = try await apiManager.request(
     UserRouter.getUser,
     retryConfiguration: retryConfiguration
 )
 ```
 */
open class APIManager: APIManaging, Retryable {
    // MARK: Public variables
    /// Default JSONDecoder implementation
    open var defaultDecoder: JSONDecoder {
        JSONDecoder()
    }
    
    // MARK: Private variables
    private let requestAdapters: [RequestAdapting]
    private let responseProcessors: [ResponseProcessing]
    private let errorProcessors: [ErrorProcessing]
    private let sessionId: String
    private var responseProvider: ResponseProviding
    public private(set) var urlSessionIsInvalidated = false

    internal var retryCounter = Counter()

    public init(
        urlSession: URLSession = .init(configuration: .default),
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        // generate session id in readable format
        if #unavailable(iOS 15) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            sessionId = dateFormatter.string(from: Date())
        } else {
            sessionId = Date().ISO8601Format()
        }
        
        self.responseProvider = urlSession
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
    }
    
    public init(
        responseProvider: ResponseProviding,
        requestAdapters: [RequestAdapting] = [],
        responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
        errorProcessors: [ErrorProcessing] = []
    ) {
        // generate session id in readable format
        if #unavailable(iOS 15) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            sessionId = dateFormatter.string(from: Date())
        } else {
            sessionId = Date().ISO8601Format()
        }
        self.responseProvider = responseProvider
        self.requestAdapters = requestAdapters
        self.responseProcessors = responseProcessors
        self.errorProcessors = errorProcessors
    }
    
    @discardableResult
    open func request(_ endpoint: Requestable, retryConfiguration: RetryConfiguration?) async throws -> Response {
        // create identifiable request from endpoint
        let endpointRequest = EndpointRequest(endpoint, sessionId: sessionId)
        return try await request(endpointRequest, retryConfiguration: retryConfiguration)
    }
}

// MARK: URL Session Invalidation

public extension APIManager {
    func setResponseProvider(_ provider: ResponseProviding) {
        responseProvider = provider
        urlSessionIsInvalidated = false
    }

    func invalidateUrlSession() async {
        // Cannot invalidate urlSession if using a different ResponseProviding implementation.
        guard let urlSession = responseProvider as? URLSession else {
            return
        }

        await urlSession.allTasks.forEach { $0.cancel() }
        urlSession.invalidateAndCancel()
        urlSessionIsInvalidated = true
    }
}

private extension APIManager {
    func request(
        _ endpointRequest: EndpointRequest,
        retryConfiguration: RetryConfiguration?
    ) async throws -> Response {
        do {
            // create original url request
            var request = try endpointRequest.endpoint.asRequest()
            
            // adapt request with all adapters
            request = try await requestAdapters.adapt(request, for: endpointRequest)

            guard !urlSessionIsInvalidated else {
                throw APIManagerError.invalidUrlSession
            }

            // get response for given request (usually fires a network request via URLSession)
            var response = try await responseProvider.response(for: request)
            
            // process request
            response = try await responseProcessors.process(response, with: request, for: endpointRequest)
                        
            // reset retry count
            await retryCounter.reset(for: endpointRequest.id)
            
            return response
        } catch {
            do {
                // If retry fails (retryCount is 0 or Task.sleep thrown), catch the error and process it with `ErrorProcessing` plugins.
                try await sleepIfRetry(
                    for: error,
                    endpointRequest: endpointRequest,
                    retryConfiguration: retryConfiguration
                )
                return try await request(endpointRequest, retryConfiguration: retryConfiguration)
            } catch {
                // error processing
                throw await errorProcessors.process(error, for: endpointRequest)
            }
        }
    }
}
