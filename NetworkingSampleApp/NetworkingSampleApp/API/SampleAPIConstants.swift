//
//  SampleAPIConstants.swift
//  NetworkingSampleApp
//
//  Created by Tomas Cejka on 03.02.2022.
//

import Foundation

/// Constants for sample API calling regres.in
enum SampleAPIConstants {
    static let userHost = "https://reqres.in/api"
    static let authHost = "https://nonexistentmockauth.com/api"
    // swiftlint:disable:next force_unwrapping
    static let uploadURL = URL(string: "https://httpbin.org/post")!
    static let validEmail = "eve.holt@reqres.in"
    static let validPassword = "cityslicka"
    static let videoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
}
