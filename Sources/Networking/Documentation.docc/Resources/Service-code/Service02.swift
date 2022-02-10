//
//  Service.swift
//
//
//  Created by Martin Vidovic on 10.02.2022.
//

import Foundation
import Networking
import Combine

final class Service {
    let manager: APIManaging

    init(manager: APIManaging = ExampleApiLayerManager()) {
        self.manager = manager
    }
}
