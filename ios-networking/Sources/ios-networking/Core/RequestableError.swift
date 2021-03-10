//
//  RequestableError.swift
//  STRV_template
//
//  Created by Tomas Cejka on 11.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// Error for endpoints composing URL request
public enum RequestableError: Error {
    case invalidURLComponents
}
