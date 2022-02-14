# Getting started with Networking

Easy to understand and use Networking library and its functionality. 

## Overview

``Networking`` is library inspired by [Moya](https://github.com/Moya/Moya) and [Alamofire](https://github.com/Alamofire/Alamofire). Comparing to the frameworks mentioned before Networking covers just most common REST API networking cases and provides additional features to help developers with writing UI tests or debugging issues.

### Authorized request
Request with valid and non-expired authentication looks like as you can see in picture:
- Aplication send request, 
- Networking library adds to it authorization, 
- BE validates authorization,
- BE sends response.

![An authorized request to Backend.](AuthorizedRequest.png)

### Unauthorized request
Request with valid and expired authentication looks like as you can see in picture:
- Aplication send request, 
- Networking library adds to it authorization,
- BE validates authorization -> returns Error,
- Networking will send Request for new authorization token,
    - This request is defined in application but called in library,
- BE sends response -> new authorization token,
- original request is sent again with updated authorization token,
- BE returns response.

![An unauthorized request to Backend.](UnauthorizedRequest.png)

### Activity Diagram
This section is specifically about flow of code.
- Application send request from ``APIManaging`` object,
- This `URLRequest` is then adapted with ``RequestAdapting`` classes, some of them are prepared and ready to use. New ones  can be created in application. Those adapters must be specified in exact order library should use them,
- After modifying request, library sends it to backend,
- Backend returns ``Response``,
- This ``Response`` is then processed with ``ResponseProcessing`` classes, some of them are prepared and ready to use. New ones can be created in application. Those processors must be specified in exact order library should use them,
- If response is successful, `Decodable` object is sent to application.
- Otherwise, if error occured, based on that, ``RetryConfiguration`` will handle retrying, or when error response means that user authentication token is expired, ``AuthenticationProviding`` which is defined in application, but called from library, will be called and after receiving new token (and saving it to keychain) it will automatically call original request again with new authorization token.

![Activity Diagram.](ActivtyDiagram.png)

