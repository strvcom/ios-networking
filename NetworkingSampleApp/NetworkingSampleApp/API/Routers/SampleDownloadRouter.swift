//
//  SampleDownloadRouter.swift
//
//
//  Created by Matej Molnár on 07.03.2023.
//

import Foundation
import Networking

/// Implementation of sample API router
enum SampleDownloadRouter: Requestable {
    case download(url: URL)
    
    var baseURL: URL {
        switch self {
        case let .download(url):
            return url
        }
    }

    var path: String {
        switch self {
        case .download:
            return ""
        }
    }
}
