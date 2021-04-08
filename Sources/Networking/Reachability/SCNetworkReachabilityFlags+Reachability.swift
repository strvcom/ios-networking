//
//  SCNetworkReachabilityFlags+Reachability.swift
//  STRV_template
//
//  Created by Tomas Cejka on 19.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import SystemConfiguration

// MARK: - Extension wrapping SCNetworkReachabilityFlags to more usable format

extension SCNetworkReachabilityFlags {
    var connection: ConnectionType {
        guard isReachableFlagSet else {
            return .unavailable
        }

        // If we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
        #if targetEnvironment(simulator)
            return .wifi
        #else
            var connection: ConnectionType = .unavailable

            if !isConnectionRequiredFlagSet {
                connection = .wifi
            }

            if isConnectionOnTrafficOrDemandFlagSet {
                if !isInterventionRequiredFlagSet {
                    connection = .wifi
                }
            }

            if isOnWWANFlagSet {
                connection = .cellular
            }

            return connection
        #endif
    }

    var isOnWWANFlagSet: Bool {
        #if os(iOS)
            return contains(.isWWAN)
        #else
            return false
        #endif
    }

    var isReachableFlagSet: Bool {
        contains(.reachable)
    }

    var isConnectionRequiredFlagSet: Bool {
        contains(.connectionRequired)
    }

    var isInterventionRequiredFlagSet: Bool {
        contains(.interventionRequired)
    }

    var isConnectionOnTrafficFlagSet: Bool {
        contains(.connectionOnTraffic)
    }

    var isConnectionOnDemandFlagSet: Bool {
        contains(.connectionOnDemand)
    }

    var isConnectionOnTrafficOrDemandFlagSet: Bool {
        !intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }

    var isTransientConnectionFlagSet: Bool {
        contains(.transientConnection)
    }

    var isLocalAddressFlagSet: Bool {
        contains(.isLocalAddress)
    }

    var isDirectFlagSet: Bool {
        contains(.isDirect)
    }

    var isConnectionRequiredAndTransientFlagSet: Bool {
        intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }

    var description: String {
        let wwan = isOnWWANFlagSet ? "W" : "-"
        let reachable = isReachableFlagSet ? "R" : "-"
        let connectionRequired = isConnectionRequiredFlagSet ? "c" : "-"
        let transientConnection = isTransientConnectionFlagSet ? "t" : "-"
        let interventionRequired = isInterventionRequiredFlagSet ? "i" : "-"
        let connectionOnTraffic = isConnectionOnTrafficFlagSet ? "C" : "-"
        let connectionOnDemand = isConnectionOnDemandFlagSet ? "D" : "-"
        let localAddress = isLocalAddressFlagSet ? "l" : "-"
        let direct = isDirectFlagSet ? "d" : "-"

        return "\(wwan)\(reachable) \(connectionRequired)\(transientConnection)\(interventionRequired)\(connectionOnTraffic)\(connectionOnDemand)\(localAddress)\(direct)"
    }
}
