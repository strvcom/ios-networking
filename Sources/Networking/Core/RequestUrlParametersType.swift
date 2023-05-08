//
//  RequestableUrlParametersType.swift
//  
//
//  Created by Dominika Gajdová on 08.05.2023.
//

import Foundation

public struct RequestUrlParametersType {
    let parameters: [String: Any]
    let arrayEncoding: ArrayEncoding
    
    init(_ parameters: [String : Any], arrayEncoding: ArrayEncoding = .individual) {
        self.parameters = parameters
        self.arrayEncoding = arrayEncoding
    }
}
