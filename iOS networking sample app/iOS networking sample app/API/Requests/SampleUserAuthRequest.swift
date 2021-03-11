//
//  SampleUserAuthRequest.swift
//  ios networking sample app
//
//  Created by Tomas Cejka on 11.03.2021.
//

import Foundation

struct SampleUserAuthRequest: Encodable {
    let email: String?
    let password: String?
}
