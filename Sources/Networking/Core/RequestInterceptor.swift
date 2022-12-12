//
//  RequestInterceptor.swift
//  Networking
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Define modifiers working before & after request

/// A modifier which adapts a request and also processes a response.
public typealias RequestInterceptor = RequestAdapting & ResponseProcessing & ErrorProcessing
