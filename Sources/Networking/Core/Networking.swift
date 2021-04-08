//
//  Networking.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Combine
import Foundation

// MARK: - Defines networking layer which allows to make a request
// URLSession or some mock class that only reads testing responses

public protocol Networking {
    func requestPublisher(for: URLRequest) -> AnyPublisher<Response, NetworkError>
}
