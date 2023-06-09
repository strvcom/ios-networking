# Networking

A networking layer using native `UrlSession` and Swift concurrency.

## Overview
Heavily inspired by Moya, the networking layer's philosophy is focused on creating individual endpoint routers, transforming them into a valid URLRequest objects and applying optional adapters and processors in the network call pipeline.

## Router
By conforming to the ``Requestable`` protocol, you can define endpoint definitions containing the elementary HTTP request components necessary to create valid HTTP requests.
<br>**Recommendation:** Follow the `Router` naming convention to explicitly indicate the usage of a router pattern.

### Example
```
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
```
init(
    urlSession: URLSession = .init(configuration: .default),
    requestAdapters: [RequestAdapting] = [],
    responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
    errorProcessors: [ErrorProcessing] = []
)
```

2. Using custom response provider by conforming to ``ResponseProviding``.
```
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
```
func request(
  _ endpoint: Requestable,
  retryConfiguration: RetryConfiguration?
) async throws -> Response
```
2. Result is custom decodable object.
```
func request<DecodableResponse: Decodable>(
  _ endpoint: Requestable,
  decoder: JSONDecoder,
  retryConfiguration: RetryConfiguration?
) async throws -> DecodableResponse
```

### Example
In the most simple form, the network request looks like this:

```
try await apiManager.request(UserRouter.getUser)
```

If you specify object type, the APIManager will automatically perform the decoding (given the received JSON correctly maps to the decodable). You can also specify a custom json decoder.

```
let userResponse: UserResponse = try await apiManager.request(UserRouter.getUser)
```

Provide a custom after failure ``RetryConfiguration``, specifying the count of retries, delay and a handler that determines whether the request should be tried again. Otherwise, ``RetryConfiguration/default`` configuration is used.

```
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
```
init(
    urlSessionConfiguration: URLSessionConfiguration = .default,
    requestAdapters: [RequestAdapting] = [],
    responseProcessors: [ResponseProcessing] = [StatusCodeProcessor.shared],
    errorProcessors: [ErrorProcessing] = []
)
```

Adapters and processors are passed during initialisation and cannot be changed afterwards.

The DownloadAPIManager contains a public property that enables you to keep track of current tasks in progress.
```
var allTasks: [URLSessionDownloadTask] { get async }
```
There are three methods provided by the ``DownloadAPIManaging`` protocol:

1. Request download for a given endpoint. Returns a standard (URLSessionDownloadTask, Response) result for the HTTP handshake. This result is not the actual downloaded file, but the HTTP response received after the download is initiated.
```
func downloadRequest(
    _ endpoint: Requestable,
    resumableData: Data? = nil,
    retryConfiguration: RetryConfiguration?
) async throws -> DownloadResult
```

2. Get progress async stream for a given task to observe task download progress and state.
```
func progressStream(for task: URLSessionTask) -> AsyncStream<URLSessionTask.DownloadState>
```

The `DownloadState` struct provides you with information about the download itself, including bytes downloaded, total byte size of the file being downloaded or the error if any occurs.

3. Invalidate download session in case DownloadAPIManager is not used as singleton to prevent memory leaks.
```
func invalidateSession(shouldFinishTasks: Bool = false)
```
DownloadAPIManager is not deallocated from memory since URLSession is holding a reference to it. If you wish to use new instances of the DownloadAPIManager, don't forget to invalidate the session if it is not needed anymore.

## Retry ability
Both APIManager and DownloadAPIManager allow for configurable retry mechanism.

```
let retryConfiguration = RetryConfiguration(retries: 2, delay: .constant(1)) { error in 
    // custom logic here that determines whether the request should be retried
    // e.g you can only retry with 5xx http error codes
}
```

## Interceptors
Interceptors are useful pieces of code that modify request/response in the network request pipeline.
![Interceptors diagram](interceptors-diagram.png)

There are three types you can leverage:<br>

``RequestAdapting``

Adapters are request transformable components that perform operations on the URLRequest before it is dispatched. They are used to further customise HTTP requests before they are carried out by editing the URLRequest (e.g updating headers).

``ResponseProcessing``

Processors are modifying the URLResponse received after a successful network request.

``RequestInterceptor``

Interceptors handle both adapting and processing.

By conforming to these protocols, you can create your own adaptors/processors/interceptors. In the following part, interceptors provided by Networking are introduced.

## Request Interceptors

### Logging
Networking provides a default ``LoggingInterceptor`` which internally uses `os_log` to pretty print requests/responses. You can utilise it to get logging console output either for requests, responses or both.

```
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

```
let authorizationManager = CustomAuthorizationManager()
let authorizationInterceptor = AuthorizationTokenInterceptor(authorizationManager: authorizationManager)
APIManager(
    //
    requestAdapters: [authorizationInterceptor],
    responseProcessors: [authorizationInterceptor],
    //
)
```

```
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

```
APIManager(
    //    
    responseProcessors: [StatusCodeProcessor.shared],
    //
)
```

### Storage
Networking provides an ``EndpointRequestStorageProcessor`` which allows for requests and responses to be saved locally into the file system.

Initialise by optionally providing a `FileManager` instance, `JSONEncoder` to be used during request/response data encoding and a configuration. The configuration allows you to set a `storedSessionsLimit` and optionally a multiPeerSharing configuration if you wish to utilize the multipeer connectivity feature for sharing the ``EndpointRequestStorageModel`` with devices using the `MultipeerConnectivity` framework.

```
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
```
http://example.com?filter=1,2,3
```

2. Individual (default)
```
http://example.com?filter=1&filter=2&filter=3
```

### Example
```
var urlParameters: [String: Any]? { 
     ["filter": ArrayParameter([1, 2, 3], arrayEncoding: .individual)]
}
```
