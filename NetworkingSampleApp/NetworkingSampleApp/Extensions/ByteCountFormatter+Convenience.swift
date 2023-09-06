//
//  ByteCountFormatter+Convenience.swift
//  NetworkingSampleApp
//
//  Created by Tony Ngo on 30.06.2023.
//

import Foundation

extension ByteCountFormatter {
    static let megaBytesFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .file
        return formatter
    }()
}
