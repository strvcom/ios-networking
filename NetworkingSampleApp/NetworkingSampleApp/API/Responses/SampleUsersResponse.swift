//
//  SampleUsersResponse.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 07.04.2021.
//

import Foundation

/// Data structure of sample API user list response
struct SampleUsersResponse: Codable {
    let page: Int
    let data: [SampleUserResponse]
}
