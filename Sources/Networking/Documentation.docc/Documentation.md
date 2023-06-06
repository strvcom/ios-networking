# Networking

A networking layer using native `UrlSession` and Swift concurrency.

## Overview
Heavily inspired by Moya, the networking layer's philosophy is focused on creating individual endpoint routers, transforming them into a valid URLRequest objects and applying optional interceptors and processors in the network call pipeline.

## Router
By conforming to the ``Requestable`` protocol, you can define endpoint definitions containing the elementary HTTP request components necessary to create valid HTTP requests.
<br> **Recommendation:** Follow the `Router` naming convention to explicitly indicate the usage of a router pattern.

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
DownloadAPIManager is responsible for the creation and management of a network file download. It conforms to the ``DownloadAPIManaging`` protocol which allows you to define your own custom DownloadAPIManager if needed.



## Retry ability

## Interceptors

### Authorization

### Logging

## Processors

### Status Code

### Storage 

### Multipeer Connectivity
