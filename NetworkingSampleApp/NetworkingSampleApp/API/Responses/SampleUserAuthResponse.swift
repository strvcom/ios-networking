//
//  SampleUserAuthResponse.swift
//  networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation
import Networking

/// Data structure of sample API authentication response
struct SampleUserAuthResponse: Decodable {
    var token: String
}
