//
//  AuthenticationProviding.swift
//
//
//  Created by Tomas Cejka on 13.09.2021.
//

import Foundation

public protocol AuthenticationProviding {
    func authorizeRequest(_ request: URLRequest) -> Result<URLRequest, AuthenticationError>
}
