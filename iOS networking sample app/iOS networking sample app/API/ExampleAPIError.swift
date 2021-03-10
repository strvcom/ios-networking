//
//  ExampleAPIError.swift
//  STRV_template
//
//  Created by Tomas Cejka on 10.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

struct ExampleAPIError: Decodable, Error, LocalizedError {
  // fields that model your error
    let error: String?
 
    var errorDescription: String? {
        "Custom error from api, message: \(error ?? "unknown"))"
    }
}
