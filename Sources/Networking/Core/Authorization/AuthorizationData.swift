//
//  AuthorizationData.swift
//  
//
//  Created by Dominika Gajdová on 20.12.2022.
//

import Foundation

/// Defines the data the Authorization header is going to be containing.
/// In case of oAuth, it's going to be Bearer token
public protocol AuthorizationData {
    var header: String { get }
}
