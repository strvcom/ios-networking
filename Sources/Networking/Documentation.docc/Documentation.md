# ``Networking``

The lightweight library for API calls management. The library is built upon URL session and provides most common networking features.

## Overview

``Networking`` is library inspired by [Moya](https://github.com/Moya/Moya) and [Alamofire](https://github.com/Alamofire/Alamofire). Comparing to the frameworks mentioned before Networking covers just most common REST API networking cases and provides additional features to help developers with writing UI tests or debugging issues.

### Networking supports
 * simple definition of API endpoints ``Requestable``
 * automatic storage of requests and responses ``EndpointRequestStorageProcessor``
 * use stored mock data as default networking layer ``SampleDataNetworking``
 * default keychain authentication managers ``KeychainAuthenticationTokenManager``, ``KeychainAuthenticationCredentialsManager``
 * reachability (combine version) ``Reachability``

### Architecture



Modifiers - Adapters, processors, interceptors
APIManaging
Reachability
Authentication


## Topics

### Main components

- ``Requestable``
- ``EndpointRequest``
- ``Networking/Networking``
- ``APIManaging``
- ``RequestInterceptor``
- ``Response``
- ``AuthenticationManaging``
