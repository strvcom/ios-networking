//
//  SampleUserAuthRequest.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation

/// Model for sample API authentication request using credentials
struct SampleUserAuthRequest: Encodable {
    let email: String?
    let password: String?
}
