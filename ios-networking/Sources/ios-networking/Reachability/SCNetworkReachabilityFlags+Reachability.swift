//
//  SCNetworkReachabilityFlags+Reachability.swift
//  STRV_template
//
//  Created by Tomas Cejka on 19.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Foundation
import SystemConfiguration

extension SCNetworkReachabilityFlags {

    typealias Connection = Reachability.Connection

    var connection: Connection {
        guard isReachableFlagSet else {
            return .unavailable
        }

        // If we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
        #if targetEnvironment(simulator)
        return .wifi
        #else
        var connection = Connection.unavailable

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
        return contains(.reachable)
    }
    var isConnectionRequiredFlagSet: Bool {
        return contains(.connectionRequired)
    }
    var isInterventionRequiredFlagSet: Bool {
        return contains(.interventionRequired)
    }
    var isConnectionOnTrafficFlagSet: Bool {
        return contains(.connectionOnTraffic)
    }
    var isConnectionOnDemandFlagSet: Bool {
        return contains(.connectionOnDemand)
    }
    var isConnectionOnTrafficOrDemandFlagSet: Bool {
        return !intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    var isTransientConnectionFlagSet: Bool {
        return contains(.transientConnection)
    }
    var isLocalAddressFlagSet: Bool {
        return contains(.isLocalAddress)
    }
    var isDirectFlagSet: Bool {
        return contains(.isDirect)
    }
    var isConnectionRequiredAndTransientFlagSet: Bool {
        return intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
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
