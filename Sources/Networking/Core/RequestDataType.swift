//
//  RequestDataType.swift
//  STRV_template
//
//  Created by Tomas Cejka on 11.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Defines various request data types to be sent in body

public enum RequestDataType {
    case noData
    case encodable(Encodable, encoder: JSONEncoder = JSONEncoder())
}
