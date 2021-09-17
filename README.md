# **WIP**

# Networking
The lightweight library for api calls management. The library is build upon URL session.  

**Networking supports**
 * simple definition of API endpoints
 * automatic storage of requests & usage as mock data
 * default keychain authentication token manager
 * reachability (combine version)

## Architecture ##
Modifiers - Adapters, processors, interceptors
APIManaging
Reachability
Authentication

## Main compoments ##
### Requestable ###
``` swift
// MARK: - Endpoint definition

public protocol Requestable: EndpointIdentifiable {
    var baseURL: URL { get }

    var path: String { get }

    var method: HTTPMethod { get }

    var urlParameters: [String: Any]? { get }

    var headers: [String: String]? { get }

    var acceptableStatusCodes: Range<HTTPStatusCode>? { get }

    var dataType: RequestDataType? { get }

    var isAuthenticationRequired: Bool { get }

    func encodeBody() throws -> Data?

    func asRequest() throws -> URLRequest
}
```
APIManager
KeychainAuthenticationTokenManager
### Usage example ###
**API manager**
``` swift 
// MARK: - Setup API manager
var apiManager: APIManager = {
    APIManager(
        requestAdapters: [
            LoggingInterceptor()
        ],
        responseProcessors: [
            StatusCodeProcessor(),
            AuthorizationTokenInterceptor(
                authenticationProvider: keychainAuthenticationTokenManager
            ),
            LoggingInterceptor()
        ]
    )
}()
```
**API call**
``` swift 
// MARK: - Call API defined by endpoint route
apiManager
    .request(
        SampleUserRouter.users(page: 2)
    )
    .sink { ... }
```
**Authentication**
``` swift
// MARK: - Keychain authentication token manager
lazy var keychainAuthenticationTokenManager = KeychainAuthenticationTokenManager(
    refreshAuthenticationTokenManager: self
)

// MARK: - RefreshAuthenticationTokenManaging
func refreshAuthenticationToken(_ refreshToken: String) -> AnyPublisher<AuthenticationTokenData, AuthenticationError> {
    apiManager
            .request(...)
}
```
**Reachability**
``` swift
lazy var reachability: Reachability? = try? Reachability()
reachability?.connection
    .sink {...}
    .store(in: &cancellables)
```
## Schedule
 [X]  init library with sample app

 [X] keychain default authentication manager 

 [ ] retry logic
 
 [ ] tests

