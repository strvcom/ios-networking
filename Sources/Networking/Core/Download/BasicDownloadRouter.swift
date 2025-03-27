//
//  BasicDownloadRouter.swift
//
//
//  Created by Matej Molnár on 08.01.2024.
//

import Foundation

/// A Router used for basic use case of downloading a file from a URL.
struct BasicDownloadRouter: Requestable {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    var baseURL: URL {
        fileURL
    }

    var path: String {
        ""
    }
}
