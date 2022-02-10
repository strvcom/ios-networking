//
//  ExampleApiLayerManager.swift
//  
//
//  Created by Martin Vidovic on 10.02.2022.
//

import Combine
import Foundation
import Networking


final class ExampleApiLayerManager {
    private(set) lazy var apiManager: APIManager = {
        return APIManager(
            network: <#T##Networking#>,
            authenticationManager: <#T##AuthenticationManaging?#>,
            requestAdapters: <#T##[RequestAdapting]#>,
            responseProcessors: <#T##[ResponseProcessing]#>
        )
    }()
}
