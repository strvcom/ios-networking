//
//  ResponseProviding.swift
//  
//
//  Created by Matej Molnár on 04.01.2023.
//

import Foundation

public protocol ResponseProviding {
    func response(for request: URLRequest) async throws -> Response
}

extension URLSession: ResponseProviding {
    public func response(for request: URLRequest) async throws -> Response {
        try await data(for: request)
    }
}
