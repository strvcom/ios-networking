//
//  File.swift
//
//
//  Created by Matej Molnár on 29.12.2023.
//

import Foundation

/// The only singleton actor in this library where all networking related operations should synchronize.
@globalActor public actor NetworkingActor {
    public static let shared = NetworkingActor()
}
