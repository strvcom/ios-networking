//
//  RequestInterceptor.swift
//  Networking
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Define modifiers working before & after request

/// Interceptors are modifiers which adapt request and process response
public typealias RequestInterceptor = RequestAdapting & ResponseProcessing
