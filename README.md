# Networking

![Coverage](https://img.shields.io/badge/Coverage-100%25-darkgreen?style=flat-square)
![Platforms](https://img.shields.io/badge/Platforms-iOS_iPadOS_macOS_watchOS-lightgrey?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9+-blue?style=flat-square)

A networking layer using native `URLSession` and Swift concurrency.

- [Requirements](#requirements)
- [Installation](#installation)
- [Overview](#overview)
- [Making requests](#making-requests)
- [Downloading files](#downloading-files)
- [Uploading files](#uploading-files)
- [Request authorization](#request-authorization)
- [Retry-ability](#retry-ability)
- [Modifiers](#modifiers)
- [Associated array query parameters](#associated-array-query-parameters)

## Requirements

- iOS/iPadOS 15.0+, macOS 12.0+, watchOS 9.0+
- Xcode 14+
- Swift 5.9+

## Installation

You can install the library with [Swift Package Manager](https://swift.org/package-manager/). Once you have your Swift package set up, adding Dependency Injection as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/strvcom/ios-networking.git", .upToNextMajor(from: "0.0.4"))
]
```

## Overview
Heavily inspired by Moya, the networking layer's philosophy is focused on creating individual endpoint routers, transforming them into a valid URLRequest objects and applying optional adapters and processors in the network call pipeline utilising native `URLSession` under the hood.

## Making requests
There is no 1 line way of making a request from scratch in order to ensure consistency and better structure. First we need to define a Router by conforming to [Requestable](https://strv.github.io/ios-networking/documentation/networking/requestable) protocol. Which in the simplest form can look like this:
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

Then we can make a request on an [APIManager](https://strv.github.io/ios-networking/documentation/networking/apimanager) instance, which is responsible for handling the whole request flow.
```swift
let response = try await APIManager().request(UserRouter.getUser)
```
If you specify object type, the [APIManager](https://strv.github.io/ios-networking/documentation/networking/apimanager) will automatically perform the decoding (given the received JSON correctly maps to the decodable). You can also specify a custom json decoder.

```swift
let userResponse: UserResponse = try await apiManager.request(UserRouter.getUser)
```

## Downloading files
Downloads are being handled by a designated [DownloadAPIManager](https://strv.github.io/ios-networking/documentation/networking/downloadapimanager). Here is an example of a basic form of file download from a `URL`. It returns a tuple of `URLSessionDownloadTask` and [Response](https://strv.github.io/ios-networking/documentation/networking/response) (result for the HTTP handshake).
```swift
let (task, response) = try await DownloadAPIManager().request(url: URL)
```

You can then observe the download progress for a given `URLSessionDownloadTask`
```swift
for try await downloadState in downloadAPIManager.shared.progressStream(for: task) {
    ...
}
```

In case you need to provide some specific info in the request, you can define a type conforming to [Requestable](https://strv.github.io/ios-networking/documentation/networking/requestable) protocol and pass that to the [DownloadAPIManager](https://strv.github.io/ios-networking/documentation/networking/downloadapimanager) instead of the `URL`.

## Uploading files
Uploads are being handled by a designated [UploadAPIManager](https://strv.github.io/ios-networking/documentation/networking/uploadapimanager). Here is an example of a basic form of file upload to a `URL`. It returns an [UploadTask](https://strv.github.io/ios-networking/documentation/networking/uploadtask) which is a struct that represents + manages a `URLSessionUploadTask` and provides its state.
```swift
let uploadTask = try await uploadManager.upload(.file(fileUrl), to: "https://upload.com/file")
```

You can then observe the upload progress for a given [UploadTask](https://strv.github.io/ios-networking/documentation/networking/uploadtask)
```swift
for await uploadState in await uploadManager.stateStream(for: task.id) {
...
}
```

In case you need to provide some specific info in the request, you can define a type conforming to [Requestable](https://strv.github.io/ios-networking/documentation/networking/requestable) protocol and pass that to the [UploadAPIManager](https://strv.github.io/ios-networking/documentation/networking/uploadapimanager) instead of the upload `URL`.

## Retry-ability
Both [APIManager](https://strv.github.io/ios-networking/documentation/networking/apimanager) and [DownloadAPIManager](https://strv.github.io/ios-networking/documentation/networking/downloadapimanager) allow for configurable retry mechanism. You can provide a custom after failure [RetryConfiguration](https://strv.github.io/ios-networking/documentation/networking/retryconfiguration), specifying the count of retries, delay and a handler that determines whether the request should be tried again. Otherwise, [RetryConfiguration.default](https://strv.github.io/ios-networking/documentation/networking/retryconfiguration/default) configuration is used.

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
![Interceptors diagram](Sources/Networking/Documentation.docc/Resources/interceptors-diagram.png)

There are three types you can leverage:<br>

[RequestAdapting](https://strv.github.io/ios-networking/documentation/networking/requestadapting)

Adapters are request transformable components that perform operations on the URLRequest before it is dispatched. They are used to further customise HTTP requests before they are carried out by editing the URLRequest (e.g updating headers).

[ResponseProcessing](https://strv.github.io/ios-networking/documentation/networking/responseprocessing)

Response processors are handling the ``Response`` received after a successful network request.

[ErrorProcessing](https://strv.github.io/ios-networking/documentation/networking/errorprocessing)

Error processors are handling the `Error` received after a failed network request.

[RequestInterceptor](https://strv.github.io/ios-networking/documentation/networking/requestinterceptor)

Interceptors handle both adapting and response/error processing.

By conforming to these protocols, you can create your own adaptors/processors/interceptors.

Here is list of classes provided by this library which implement these protocols:
- [StatusCodeProcessor](https://strv.github.io/ios-networking/documentation/networking/statuscodeprocessor)
- [EndpointRequestStorageProcessor](https://strv.github.io/ios-networking/documentation/networking/endpointrequeststorageprocessor)
- [LoggingInterceptor](https://strv.github.io/ios-networking/documentation/networking/logginginterceptor)
- [AuthorizationTokenInterceptor](https://strv.github.io/ios-networking/documentation/networking/authorizationtokeninterceptor)

## Request authorization
Networking provides a default authorization handling for OAuth scenarios. In order to utilise this we
have to first create our own implementation of [AuthorizationStorageManaging](https://strv.github.io/ios-networking/documentation/networking/authorizationstoragemanaging) and [AuthorizationManaging](https://strv.github.io/ios-networking/documentation/networking/authorizationmanaging) which we inject into to  [AuthorizationTokenInterceptor](https://strv.github.io/ios-networking/documentation/networking/authorizationtokeninterceptor) and then pass
it to the [APIManager](https://strv.github.io/ios-networking/documentation/networking/apimanager) as both adapter and processor.

```swift
let authManager = AuthorizationManager()
let authorizationInterceptor = AuthorizationTokenInterceptor(authorizationManager: authManager)
let apiManager = APIManager(
            requestAdapters: [authorizationInterceptor],
            responseProcessors: [authorizationInterceptor]
        )
```

After login we have to save the [AuthorizationData](https://strv.github.io/ios-networking/documentation/networking/authorizationdata) to the [AuthorizationManager](https://strv.github.io/ios-networking/documentation/networking/authorizationmanager).

```swift
let response: UserAuthResponse = try await apiManager.request(
    UserRouter.loginUser(request)
)
try await authManager.storage.saveData(response.authData)
```

Then we can simply define which request should be authorised via `isAuthenticationRequired` property of [Requestable](https://strv.github.io/ios-networking/documentation/networking/requestable) protocol.  

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
When specifying urlParameters in the endpoint definition, use an [ArrayParameter](https://strv.github.io/ios-networking/documentation/networking/arrayparameter) to define multiple values for a single URL query parameter. The struct lets you decide which [ArrayEncoding](https://strv.github.io/ios-networking/documentation/networking/arrayencoding) will be used during the creation of the URL.

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
