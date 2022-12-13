//
//  SampleSongsResponse.swift
//  NetworkingSampleApp
//
//  Created by Dominika Gajdová on 12.12.2022.
//

import Foundation

typealias SampleSongsResponse = [SampleSongResponse]

/// Data structure of sample API song response
struct SampleSongResponse: Codable {
    let title: String
    let artist: String
}
