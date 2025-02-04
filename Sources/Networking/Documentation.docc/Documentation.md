# Networking

- [Overview](#overview)
- [Making requests](#making-requests)
- [Downloading files](#downloading-files)
- [Uploading files](#uploading-files)
- [Retry-ability](#retry-ability)
- [Modifiers](#modifiers)
- [Request authorization](#request-authorization)
- [Associated array query parameters](#associated-array-query-parameters)

## Overview
Heavily inspired by Moya, the networking layer's philosophy is focused on creating individual endpoint routers, transforming them into a valid URLRequest objects and applying optional adapters and processors in the network call pipeline utilising native `URLSession` under the hood.

## Making requests
There is no 1 line way of making a request from scratch in order to ensure consistency and better structure. First we need to define a Router by conforming to ``Requestable`` protocol. Which in the simplest form can look like this:
```swift
enum UserRouter: Requestable {
    case getUser
    
    var baseURL: URL { 
        URL(string: "https://reqres.in/api")!
    }

    var path: String { 
        switch self {
        case .getUser: "/user"
        }
    }

    var method: HTTPMethod { 
        switch self {
        case .getUser: .get
        }
    }
}
```

Then we can make a request on an ``APIManager`` instance, which is responsible for handling the whole request flow.
```swift
let response = try await APIManager().request(UserRouter.getUser)
```
If you specify object type, the ``APIManager`` will automatically perform the decoding (given the received JSON correctly maps to the decodable). You can also specify a custom json decoder.

```swift
let userResponse: UserResponse = try await apiManager.request(UserRouter.getUser)
```

## Downloading files
Downloads are being handled by a designated ``DownloadAPIManager``. Here is an example of a basic form of file download from a `URL`. It returns a tuple of `URLSessionDownloadTask` and ``Response`` (result for the HTTP handshake).
```swift
let (task, response) = try await DownloadAPIManager().request(url: URL)
```

You can then observe the download progress for a given `URLSessionDownloadTask`
```swift
for try await downloadState in downloadAPIManager.shared.progressStream(for: task) {
    ...
}
```

In case you need to provide some specific info in the request, you can define a type conforming to ``Requestable`` protocol and pass that to the ``DownloadAPIManager`` instead of the `URL`.

## Uploading files
Uploads are being handled by a designated ``UploadAPIManager``. Here is an example of a basic form of file upload to a `URL`. It returns an ``UploadTask`` which is a struct that represents + manages a `URLSessionUploadTask` and provides its state.
```swift
let uploadTask = try await uploadManager.upload(.file(fileUrl), to: "https://upload.com/file")
```

You can then observe the upload progress for a given ``UploadTask``
```swift
for await uploadState in await uploadManager.stateStream(for: task.id) {
...
}
```

In case you need to provide some specific info in the request, you can define a type conforming to ``Requestable`` protocol and pass that to the ``UploadAPIManager`` instead of the upload `URL`.

## Retry-ability
Both ``APIManager`` and ``DownloadAPIManager`` allow for configurable retry mechanism. You can provide a custom after failure ``RetryConfiguration``, specifying the count of retries, delay and a handler that determines whether the request should be tried again. Otherwise, ``RetryConfiguration/default`` configuration is used.

```swift
let retryConfiguration = RetryConfiguration(retries: 2, delay: .constant(1)) { error in 
    // custom logic here
}
let userResponse: UserResponse = try await apiManager.request(
    UserRouter.getUser,
    retryConfiguration: retryConfiguration
)
``` 

## Modifiers
Modifiers are useful pieces of code that modify request/response in the network request pipeline.
![Interceptors diagram](interceptors-diagram.png)

There are three types you can leverage:<br>

``RequestAdapting``

Adapters are request transformable components that perform operations on the `URLRequest` before it is dispatched. They are used to further customise HTTP requests before they are carried out by editing the `URLRequest` (e.g updating headers).

``ResponseProcessing``

Response processors are handling the ``Response`` received after a successful network request.

``ErrorProcessing``

Error processors are handling the `Error` received after a failed network request.

``RequestInterceptor``

Interceptors handle both adapting and response/error processing.

By conforming to these protocols, you can create your own adaptors/processors/interceptors.

Here is list of classes provided by this library which implement these protocols:
- ``StatusCodeProcessor``
- ``EndpointRequestStorageProcessor``
- ``LoggingInterceptor``
- ``AuthorizationTokenInterceptor``

## Request authorization
Networking provides a default authorization handling for OAuth scenarios. In order to utilise this we
have to first create our own implementation of ``AuthorizationStorageManaging`` and ``AuthorizationManaging`` which we inject into to  ``AuthorizationTokenInterceptor`` and then pass it to the ``APIManager`` as both adapter and processor.

```swift
let authManager = AuthorizationManager()
let authorizationInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
let apiManager = APIManager(
            requestAdapters: [authorizationInterceptor],
            responseProcessors: [authorizationInterceptor]
        )
```

After login we have to save the ``AuthorizationData`` to the ``AuthorizationStorageManaging``.

```swift
let response: UserAuthResponse = try await apiManager.request(
    UserRouter.loginUser(request)
)
try await authManager.storage.saveData(response.authData)
```

Then we can simply define which request should be authorised via ``Requestable/isAuthenticationRequired`` property on ``Requestable`` protocol.  

```swift
extension UserRouter: Requestable {
    ...
    var isAuthenticationRequired: Bool {
        switch self {
        case .getUser, .updateUser:
            return true
        }
    }
}
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

## Invalidating URLSession
APIManager exposes a method for invalidating the current URLSession in case the current response provider is using one. THis can me handy in times it's necessary to terminate all URLSession operations and prevent URLSession from entering an broken/undefined state (this can happen for example if your app is suspended prematurely).

After calling the `invalidateUrlSession` method, a flag `urlSessionIsInvalidated` is set indicating whether the current session is invalidated or not. In case it has been invalidated, it is no longer possible to use the previously created urlSession and all usages will lead to a crash. New session has to be created and passed to APIManager instance by using the `setResponseProvider` method.
