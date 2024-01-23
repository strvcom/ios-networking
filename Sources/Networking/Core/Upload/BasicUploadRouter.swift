//
//  BasicUploadRouter.swift
//
//
//  Created by Matej Molnár on 08.01.2024.
//

import Foundation

/// A Router for basic use case of uploading file/data/multiPartForm to a given URL.
struct BasicUploadRouter: Requestable {
    let url: URL
    let uploadType: UploadType

    var baseURL: URL {
        url
    }

    var headers: [String: String]? {
        switch uploadType {
        case let .data(_, contentType):
            ["Content-Type": contentType]
        case let .file(url):
            ["Content-Type": url.mimeType]
        case let .multipart( data, _):
            ["Content-Type": "multipart/form-data; boundary=\(data.boundary)"]
        }
    }

    var path: String {
        ""
    }

    var method: HTTPMethod {
        .post
    }
}
