//
//  SampleUsersResponse.swift
//  networking sample app
//
//  Created by Tomas Cejka on 07.04.2021.
//

import Foundation

struct SampleUsersResponse: Codable {
    let page: Int
    let data: [SampleUserResponse]
}
