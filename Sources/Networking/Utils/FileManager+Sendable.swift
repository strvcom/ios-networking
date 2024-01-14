//
//  File.swift
//
//
//  Created by Matej Molnár on 27.11.2023.
//

import Foundation

// FileManager does not yet conforming to Sendable, hence we at least suppress the non-sendable warning.
extension FileManager: @unchecked Sendable {}
