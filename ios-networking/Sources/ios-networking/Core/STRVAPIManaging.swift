//
//  STRVAPIManaging.swift
//  STRV_template
//
//  Created by Jan Pacek on 04.12.2020.
//  Copyright © 2020 STRV. All rights reserved.
//

import Foundation
import Combine

// TODO: Temp name to avoid conflict with original moya api manager
public protocol STRVAPIManaging {
    func request(_ endpoint: Requestable) -> AnyPublisher<Response, Error>
    func request<Body: Decodable>(_ endpoint: Requestable, decoder: JSONDecoder) -> AnyPublisher<Body, Error>
}
