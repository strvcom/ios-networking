//
//  SampleUploadRouter.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation
import Networking
import UniformTypeIdentifiers

enum SampleUploadRouter: Requestable {
    case image
    case file(URL)
    case multipart(boundary: String)

    var baseURL: URL {
        fatalError("Provide your API base URL for upload")
    }

    var headers: [String : String]? {
        switch self {
        case .image:
            return ["Content-Type": "image/png"]
        case let .file(url):
            return ["Content-Type": url.mimeType]
        case let .multipart(boundary):
            return ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        }
    }

    var path: String {
        fatalError("Provide your API endpoint path for upload")
    }

    var method: HTTPMethod {
        .post
    }
}

private extension URL {
    var mimeType: String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
}
