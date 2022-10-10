//
//  ReachabilityError.swift
//
//  Created by Tomas Cejka on 14.03.2021.
//

import Foundation

// MARK: - Defines reachability errors

/// Errors which can be thrown when creating `SCNetworkReachability`
public enum ReachabilityError: Error {
    case failedToCreateWithAddress(sockaddr, Int32)
    case failedToCreateWithHostname(String, Int32)
    case unableToSetCallback(Int32)
    case unableToSetDispatchQueue(Int32)
    case unableToGetFlags(Int32)
}
