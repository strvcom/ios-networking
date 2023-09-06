//
//  Uploadable.swift
//  
//
//  Created by Tony Ngo on 13.06.2023.
//

import Foundation

/// Represents a data type that can be uploaded.
enum Uploadable {
    case data(Data)
    case file(URL, removeOnComplete: Bool = false)
}
