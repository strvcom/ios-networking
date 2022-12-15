//
//  SampleErrorProcessor.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 05.12.2022.
//

import Networking
import Foundation

/// Maps NetworkError's unacceptableStatusCode 400 error to SampleAPIError.
final class SampleErrorProcessor: ErrorProcessing {
    private lazy var decoder = JSONDecoder()
    
    func process(_ error: Error, for endpointRequest: EndpointRequest) -> Error {
        guard let networkError = error as? NetworkError,
              case let .unacceptableStatusCode(statusCode, _, response) = networkError,
              statusCode == 400
        else {
            return error
        }
        
        if let apiError = try? decoder.decode(SampleAPIError.self, from: response.data) {
            return apiError
        }

        return error
    }
}
