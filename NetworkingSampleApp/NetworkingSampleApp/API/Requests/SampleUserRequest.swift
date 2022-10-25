//
//  SampleUserRequest.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation

struct SampleUserRequest: Encodable {
    let name: String
    let job: String
}
