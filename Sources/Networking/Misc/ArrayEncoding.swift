//
//  ArrayEncoding.swift
//
//
//  Created by Dominika Gajdová on 08.05.2023.
//

import Foundation

/// Associated array parameters query options.
public enum ArrayEncoding {
    /// filter=1,2,3
    case commaSeparated
    /// filter=1&filter=2&filter=3
    case individual
}
