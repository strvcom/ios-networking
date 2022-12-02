//
//  SampleAPIError.swift
//  Networking
//
//  Created by Tomas Cejka on 10.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

/// Sample API custom error to show how to handle custom errors
struct SampleAPIError: Decodable, Error, LocalizedError {
    let error: String?

    var errorDescription: String? {
        "Custom error from api, message: \(error ?? "unknown"))"
    }
}
