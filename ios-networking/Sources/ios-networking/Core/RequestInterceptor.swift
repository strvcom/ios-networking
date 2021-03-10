//
//  RequestInterceptor.swift
//  STRV_template
//
//  Created by Tomas Cejka on 14.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation

// For object which works like adapter & processor modifier
public typealias RequestInterceptor = RequestAdapting & ResponseProcessing
