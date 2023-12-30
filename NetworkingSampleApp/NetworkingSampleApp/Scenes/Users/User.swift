//
//  SampleUserResponse.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 07.04.2021.
//

import Foundation

/// Data structure of sample API user response
struct User: Codable, Identifiable, Sendable {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarURL = "avatar"
    }

    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let avatarURL: URL
}
