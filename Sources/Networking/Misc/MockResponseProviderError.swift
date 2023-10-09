//
//  MockResponseProviderError.swift
//
//
//  Created by Matej Molnár on 04.01.2023.
//

import Foundation

/// An error that occurs during loading a ``Response`` from assets by `MockResponseProvider`.
enum MockResponseProviderError: Error {
    /// An indication that there was a problem with loading or decoding data from assets.
    case unableToLoadAssetData
    /// An indication that it was not possible to construct a `Response` from the loaded data.
    case unableToConstructResponse
}
