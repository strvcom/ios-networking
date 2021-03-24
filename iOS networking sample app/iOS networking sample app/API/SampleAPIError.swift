//
//  SampleAPIError.swift
//  STRV_template
//
//  Created by Tomas Cejka on 10.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import ios_networking

// Custom error
struct SampleAPIError: Decodable, Error, LocalizedError, Retriable {
    let error: String?
 
    var errorDescription: String? {
        "Custom error from api, message: \(error ?? "unknown"))"
    }
    
    var shouldRetry: Bool {
        true
    }
}
