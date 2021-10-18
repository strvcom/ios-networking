//
//  RequestInterceptor.swift
//  Networking
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// MARK: - Typealias for modifiers both before & after request

public typealias RequestInterceptor = RequestAdapting & ResponseProcessing
