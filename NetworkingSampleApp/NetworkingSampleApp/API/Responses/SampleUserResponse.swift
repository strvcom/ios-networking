//
//  SampleUserResponse.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 07.04.2021.
//

import Foundation

/// Data structure of sample API user response
struct SampleUserResponse: Codable {
    let id: Int
    let email: String?
}
