//
//  Service.swift
//
//
//  Created by Martin Vidovic on 10.02.2022.
//

import Networking
import Combine

protocol Servicing {
    func downloadUserProfile() -> AnyPublisher<Decodable, Error>
}

final class Service: Servicing {
    let manager: APIManaging

    init(manager: APIManaging = ExampleApiLayerManager()) {
        self.manager = manager
    }

    func downloadUserProfile() -> AnyPublisher<Decodable, Error>
        manager.request(UserRouter.getUserProfile)
    }
}
