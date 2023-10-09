//
//  SampleUploadRouter.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 12.06.2023.
//

import Foundation
import Networking

enum SampleUploadRouter: Requestable {
    case image
    case file(URL)
    case multipart(boundary: String)

    var baseURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: SampleAPIConstants.uploadHost)!
    }

    var headers: [String: String]? {
        switch self {
        case .image:
            ["Content-Type": "image/png"]
        case let .file(url):
            ["Content-Type": url.mimeType]
        case let .multipart(boundary):
            ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        }
    }

    var path: String {
        "/post"
    }

    var method: HTTPMethod {
        .post
    }
}
