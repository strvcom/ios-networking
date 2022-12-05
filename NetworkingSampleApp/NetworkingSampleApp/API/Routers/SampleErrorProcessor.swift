//
//  SampleErrorProcessor.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 05.12.2022.
//

import Networking

// Maps all NetworkError's unacceptableStatusCode errors to a sad smiley face.
struct SampleErrorProcessor: ErrorProcessing {
    enum SampleSadError: Error {
        case sad(emoji: String)
    }
    
    func process(_ error: Error) -> Error {
        if case NetworkError.unacceptableStatusCode(let statusCode, _, _) = error {
            return SampleSadError.sad(emoji: "So so sad \(statusCode) 😭")
        }
        
        // otherwise return unprocessed original error
        return error
    }
}
