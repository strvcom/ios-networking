# Networking

A networking layer using native `UrlSession` and Swift concurrency.

## Overview
Heavily inspired by Moya, the networking layer's philosophy is focused on creating individual endpoint routers, transforming them into a valid URLRequest objects and applying optional adapters and processors in the network call pipeline.

## Router
By conforming to the ``Requestable`` protocol, you can define endpoint definitions containing the elementary HTTP request components necessary to create valid HTTP requests.
<br>**Recommendation:** Follow the `Router` naming convention to explicitly indicate the usage of a router pattern.

### Example
```swift
enum UserRouter { 
    case getUser
    case updateUser(UpdateUserRequest)
}

extension UserRouter: Requestable {
    // The base URL address used for the HTTP call.
    var baseURL: URL { 
        URL(string: Constants.baseHost)!
    }

    // Path will be appended to the base URL.
    var path: String { 
        switch self {
        case .getUser, .updateUser:
            return "/user"
        }
    }

    // HTTPMethod used for each endpoint.
    var method: HTTPMethod { 
        switch self {
        case .getUser:
            return .get        
        case .updateUser:
            return .post
        }
    }

    // Optional body data encoded in JSON by default.
    var dataType: RequestDataType? { 
        switch self {
        case .getUser:
            return nil
        case let .updateUser(data):
            return .encodable(data)
        }
    }

    // Optional authentication requirement if AuthorizationInterceptor is used.
    var isAuthenticationRequired: Bool {
        switch self {
        case .getUser, .updateUser:
            return true
        }
    }
}
```

Some of the properties have default implementations defined in the `Requestable+Convenience` extension.

## APIManager
APIManager is responsible for the creation and management of a network call. It conforms to the ``APIManaging`` protocol which allows you to define your own custom APIManager if needed.

There are two ways to initialise the ``APIManager`` object:
1. Using URLSession as the response provider.
```swift
init(
    urlSession: URLSession = .init(configuration: .default),
    requestAdapters: [RequestAdapting] = [],
    responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
    errorProcessors: [ErrorProcessing] = []
)
```

2. Using custom response provider by conforming to ``ResponseProviding``. An example of a custom provider is ``MockResponseProvider``, which can be used for UI tests to interact with mocked data saved through "EndpointRequestStorageProcessor". To utilize them, simply move the stored session folder into the Asset catalogue.

```swift
init(
    responseProvider: ResponseProviding,
    requestAdapters: [RequestAdapting] = [],
    responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
    errorProcessors: [ErrorProcessing] = []
)
```

Adapters and processors are passed during initialisation and cannot be changed afterwards.

There are two methods provided by the ``APIManaging`` protocol:

1. Result is URLSession's default (data, response) tuple.
```swift
func request(
  _ endpoint: Requestable,
  retryConfiguration: RetryConfiguration?
) async throws -> Response
```
2. Result is custom decodable object.
```swift
func request<DecodableResponse: Decodable>(
  _ endpoint: Requestable,
  decoder: JSONDecoder,
  retryConfiguration: RetryConfiguration?
) async throws -> DecodableResponse
```

### Example
In the most simple form, the network request looks like this:

```swift
try await apiManager.request(UserRouter.getUser)
```

If you specify object type, the APIManager will automatically perform the decoding (given the received JSON correctly maps to the decodable). You can also specify a custom json decoder.

```swift
let userResponse: UserResponse = try await apiManager.request(UserRouter.getUser)
```

Provide a custom after failure ``RetryConfiguration``, specifying the count of retries, delay and a handler that determines whether the request should be tried again. Otherwise, ``RetryConfiguration/default`` configuration is used.

```swift
let retryConfiguration = RetryConfiguration(retries: 2, delay: .constant(1)) { error in 
    // custom logic here
}
let userResponse: UserResponse = try await apiManager.request(
    UserRouter.getUser,
    retryConfiguration: retryConfiguration
)
```

## DownloadAPIManager
DownloadAPIManager is responsible for the creation and management of a network file download. It conforms to the ``DownloadAPIManaging`` protocol which allows you to define your own custom DownloadAPIManager if needed. Multiple parallel downloads are supported.

The initialisation is equivalent to APIManager, except the session is created for the user based on a given `URLSessionConfiguration`:
```swift
init(
    urlSessionConfiguration: URLSessionConfiguration = .default,
    requestAdapters: [RequestAdapting] = [],
    responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
    errorProcessors: [ErrorProcessing] = []
)
```

Adapters and processors are passed during initialisation and cannot be changed afterwards.

The DownloadAPIManager contains a public property that enables you to keep track of current tasks in progress.
```swift
var allTasks: [URLSessionDownloadTask] { get async }
```
There are three methods provided by the ``DownloadAPIManaging`` protocol:

1. Request download for a given endpoint. Returns a standard (URLSessionDownloadTask, Response) result for the HTTP handshake. This result is not the actual downloaded file, but the HTTP response received after the download is initiated.
```swift
func downloadRequest(
    _ endpoint: Requestable,
    resumableData: Data? = nil,
    retryConfiguration: RetryConfiguration?
) async throws -> DownloadResult
```

2. Get progress async stream for a given task to observe task download progress and state.
```swift
func progressStream(for task: URLSessionTask) -> AsyncStream<URLSessionTask.DownloadState>
```

The `DownloadState` struct provides you with information about the download itself, including bytes downloaded, total byte size of the file being downloaded or the error if any occurs.

3. Invalidate download session in case DownloadAPIManager is not used as singleton to prevent memory leaks.
```swift
func invalidateSession(shouldFinishTasks: Bool = false)
```
DownloadAPIManager is not deallocated from memory since URLSession is holding a reference to it. If you wish to use new instances of the DownloadAPIManager, don't forget to invalidate the session if it is not needed anymore.

## UploadAPIManager
Similarly to DownloadAPIManager we have an UploadAPIManager responsible for the creation and management of network file uploads. It conforms to the ``UploadAPIManaging`` protocol which allows you to define your own custom UploadAPIManager if needed. Multiple parallel uploads are supported.

The initialisation is equivalent to APIManager, except the session is created for the user based on a given `URLSessionConfiguration`:
```swift
init(
    urlSessionConfiguration: URLSessionConfiguration = .default,
    requestAdapters: [RequestAdapting] = [],
    responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
    errorProcessors: [ErrorProcessing] = []
)
```

Adapters and processors are passed during initialisation and cannot be changed afterwards.

The UploadAPIManager contains a public property that enables you to keep track of current tasks in progress.
```swift
var activeTasks: [UploadTask] { get async }
```
``UploadAPIManaging`` defines three methods for upload based on the upload type `Data`, file `URL` and `MultipartFormData`. Each of these methods return an `UploadTask`.
An `UploadTask` is a struct which under the hood represents + manages a URLSessionUploadTask and provides its state.

After firing an upload by one of these three methods, you can get a StateStream either from the `UploadTask` itself or from the manager with the following method. 
```swift
func stateStream(for uploadTaskId: UploadTask.ID) async -> StateStream
```
The `StateStream` is a typealias for `AsyncPublisher<AnyPublisher<UploadTask.State, Never>>`.
The `UploadTask.State` struct provides you with information about the upload itself, including bytes uploaded, total byte size of the file being uploaded or the error if any occurs.

The manager also allows for retries of uploads.
```swift
    func retry(taskId: String) async throws
```

You should invalidate upload session in case UploadAPIManager is not used as singleton to prevent memory leaks.
```swift
func invalidateSession(shouldFinishTasks: Bool = false)
```
UploadAPIManager is not deallocated from memory since URLSession is holding a reference to it. If you wish to use new instances of the UploadAPIManager, don't forget to invalidate the session if it is not needed anymore.

## Retry ability
Both APIManager and DownloadAPIManager allow for configurable retry mechanism.

```swift
let retryConfiguration = RetryConfiguration(retries: 2, delay: .constant(1)) { error in 
    // custom logic here that determines whether the request should be retried
    // e.g you can only retry with 5xx http error codes
}
```

## Modifiers
Modifiers are useful pieces of code that modify request/response in the network request pipeline.
![Interceptors diagram](interceptors-diagram.png)

There are three types you can leverage:<br>

``RequestAdapting``

Adapters are request transformable components that perform operations on the URLRequest before it is dispatched. They are used to further customise HTTP requests before they are carried out by editing the URLRequest (e.g updating headers).

``ResponseProcessing``

Processors are handling the ``Response`` received after a successful network request.

``RequestInterceptor``

Interceptors handle both adapting and processing.

By conforming to these protocols, you can create your own adaptors/processors/interceptors. In the following part, modifiers provided by Networking are introduced.

## Request Interceptors

### Logging
Networking provides a default ``LoggingInterceptor`` which internally uses `os_log` to pretty print requests/responses. You can utilise it to get logging console output either for requests, responses or both.

```swift
APIManager(
    //
    requestAdapters: [LoggingInterceptor.shared],
    responseProcessors: [LoggingInterceptor.shared],
    errorProcessors: [LoggingInterceptor.shared]
    //
)
```

### Authorization
Networking provides a default authorization handling for OAuth scenarios. Use the default ``AuthorizationTokenInterceptor`` with the APIManager to obtain the behaviour of JWT Bearer authorization header injection and access token expiration refresh flow.

Start by implementing an authorization manager by conforming to ``AuthorizationManaging``. This manager requires you to provide storage defined by ``AuthorizationStorageManaging`` (where OAuth credentials will be stored) and a refresh method that will perform the refresh token network call to obtain a new OAuth pair. Optionally, you can provide custom implementations for ``AuthorizationManaging/authorizeRequest(_:)-6azlk`` (by default, this method sets the authorization header) or access token getter (by default, this method returns the access token saved in provided storage).

```swift
let authorizationManager = CustomAuthorizationManager()
let authorizationInterceptor = AuthorizationTokenInterceptor(authorizationManager: authorizationManager)
APIManager(
    //
    requestAdapters: [authorizationInterceptor],
    responseProcessors: [authorizationInterceptor],
    //
)
```

```swift
final class CustomAuthorizationManager: AuthorizationManaging {
    let storage: AuthorizationStorageManaging = CustomAuthorizationStorageManager()
        
    /// For refresh token logic, create a new instance of APIManager 
    /// without injecting `AuthorizationTokenInterceptor` to avoid cycling in refreshes    
    private let apiManager: APIManager = APIManager()
    
    func refreshAuthorizationData(with refreshToken: String) async throws -> Networking.AuthorizationData {
        // perform an network request to obtain refresh OAuth credentials
    }
}
```

## Processors

### Status Code
Each ``Requestable`` endpoint definition contains an ``Requestable/acceptableStatusCodes-9q0ur`` range of acceptable status codes. By default, these are set to `200..<400`. Networking provides a default status code processor that makes sure the received response's HTTP code is an acceptable one, otherwise an ``NetworkError/unacceptableStatusCode(statusCode:acceptedStatusCodes:response:)`` error is thrown.

```swift
APIManager(
    //    
    responseProcessors: [StatusCodeProcessor.shared],
    //
)
```

### Storage
Networking provides an ``EndpointRequestStorageProcessor`` which allows for requests and responses to be saved locally into the file system. Requests are stored in a sequential manner. Each session is kept in its own dedicated folder. The ``EndpointRequestStorageModel`` includes both successful and erroneous data.

Initialise by optionally providing a `FileManager` instance, `JSONEncoder` to be used during request/response data encoding and a configuration. The configuration allows you to set optionally a multiPeerSharing configuration if you wish to utilize the multipeer connectivity feature for sharing the ``EndpointRequestStorageModel`` with devices using the `MultipeerConnectivity` framework.

```swift
init(
    fileManager: FileManager = .default,
    jsonEncoder: JSONEncoder? = nil,
    config: Config = .default
)
```

## Associated array query parameters
When specifying urlParameters in the endpoint definition, use an ``ArrayParameter`` to define multiple values for a single URL query parameter. The struct lets you decide which ``ArrayEncoding`` will be used during the creation of the URL.

There are two currently supported encodings:

1. Comma separated
```swift
http://example.com?filter=1,2,3
```

2. Individual (default)
```swift
http://example.com?filter=1&filter=2&filter=3
```

### Example
```swift
var urlParameters: [String: Any]? { 
     ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .individual)]
}
```
