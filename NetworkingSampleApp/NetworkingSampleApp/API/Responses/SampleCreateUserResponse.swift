//
//  SampleCreateUserResponse.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 11.12.2023.
//

import Foundation

/// Data structure of sample API create user response
struct SampleCreateUserResponse: Codable {
    let id: String
    let name: String
    let job: String
    let createdAt: Date
}
