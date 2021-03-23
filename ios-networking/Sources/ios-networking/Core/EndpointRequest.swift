//
//  EndpointRequest.swift
//  STRV_template
//
//  Created by Tomas Cejka on 04.03.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Struct wrapping endpoint request with its identifier

public struct EndpointRequest: Identifiable {
    public let identifier: String
    public let endpoint: Requestable
}
