//
//  TestReachability.swift
//  STRV_template
//
//  Created by Tomas Cejka on 18.02.2021.
//  Copyright © 2021 STRV. All rights reserved.
//

import Combine
import Foundation
import SystemConfiguration

// MARK: - Manages reachability

open class Reachability {
    // network status observable
    private var reachabilityState = CurrentValueSubject<ConnectionType, ReachabilityError>(.unavailable)

    // MARK: Public publishers to observe reachability changes
    public var connection: AnyPublisher<ConnectionType, ReachabilityError> {
        reachabilityState.removeDuplicates().eraseToAnyPublisher()
    }

    public var isReachable: AnyPublisher<Bool, ReachabilityError> {
        reachabilityState
            .map { $0 != .unavailable }
            .eraseToAnyPublisher()
    }

    public var isConnected: AnyPublisher<Void, ReachabilityError> {
        isReachable
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    public var isDisconnected: AnyPublisher<Void, ReachabilityError> {
        isReachable
            .filter { !$0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    // Set to `false` to force Reachability.connection to .none when on cellular connection (default value `true`)
    public var allowsCellularConnection: Bool

    private var isRunningOnDevice: Bool = {
        #if targetEnvironment(simulator)
            return false
        #else
            return true
        #endif
    }()

    var description: String {
        flags?.description ?? "unavailable flags"
    }

    private var notifierRunning = false
    private let reachabilityRef: SCNetworkReachability
    private let reachabilitySerialQueue: DispatchQueue

    private(set) var flags: SCNetworkReachabilityFlags? {
        didSet {
            guard flags != oldValue else {
                return
            }

            switch flags?.connection {
            case .unavailable?, nil:
                reachabilityState.value = .unavailable
            case .cellular?:
                reachabilityState.value = allowsCellularConnection ? .cellular : .unavailable
            case .wifi?:
                reachabilityState.value = .wifi
            }
        }
    }

    public required init(
        reachabilityRef: SCNetworkReachability,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil
    ) {
        allowsCellularConnection = true
        self.reachabilityRef = reachabilityRef
        reachabilitySerialQueue = DispatchQueue(label: "com.strv.reachability", qos: queueQoS, target: targetQueue)
        startNotifier()
    }

    public convenience init?(
        hostname: String,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil
    ) throws {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            throw ReachabilityError.failedToCreateWithHostname(hostname, SCError())
        }
        self.init(reachabilityRef: ref, queueQoS: queueQoS, targetQueue: targetQueue)
    }

    public convenience init?(
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil
    ) throws {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)

        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            throw ReachabilityError.failedToCreateWithAddress(zeroAddress, SCError())
        }

        self.init(reachabilityRef: ref, queueQoS: queueQoS, targetQueue: targetQueue)
    }

    deinit {
        stopNotifier()
    }

    func restart() {
        reachabilityState = CurrentValueSubject<ConnectionType, ReachabilityError>(.unavailable)
        startNotifier()
    }
}

// MARK: - Private notifying methods

private extension Reachability {
    func startNotifier() {
        guard !notifierRunning else {
            return
        }

        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else {
                return
            }

            // `weakifiedReachability` is guaranteed to exist by virtue of our
            // retain/release callbacks which we provided to the `SCNetworkReachabilityContext`.
            let weakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info).takeUnretainedValue()

            // The weak `reachability` _may_ no longer exist if the `Reachability`
            // object has since been deallocated but a callback was already in flight.
            weakifiedReachability.reachability?.flags = flags
        }

        let weakifiedReachability = ReachabilityWeakifier(reachability: self)
        let opaqueWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.passUnretained(weakifiedReachability).toOpaque()

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(opaqueWeakifiedReachability),
            retain: { (info: UnsafeRawPointer) -> UnsafeRawPointer in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                _ = unmanagedWeakifiedReachability.retain()
                return UnsafeRawPointer(unmanagedWeakifiedReachability.toOpaque())
            },
            release: { (info: UnsafeRawPointer) -> Void in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                unmanagedWeakifiedReachability.release()
            },
            copyDescription: { (info: UnsafeRawPointer) -> Unmanaged<CFString> in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                let weakifiedReachability = unmanagedWeakifiedReachability.takeUnretainedValue()
                let description = weakifiedReachability.reachability?.description ?? "nil"
                return Unmanaged.passRetained(description as CFString)
            }
        )

        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            reachabilityState.send(completion: Subscribers.Completion<ReachabilityError>.failure(.unableToSetCallback(SCError())))
        }

        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            reachabilityState.send(completion: Subscribers.Completion<ReachabilityError>.failure(.unableToSetDispatchQueue(SCError())))
        }

        // Perform an initial check
        setReachabilityFlags()

        notifierRunning = true
    }

    func stopNotifier() {
        defer { notifierRunning = false }

        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
}

// MARK: - Handle SCNetwork flags

private extension Reachability {
    func setReachabilityFlags() {
        reachabilitySerialQueue.sync { [weak self] in
            guard let self = self else {
                return
            }
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags) {
                self.stopNotifier()
                reachabilityState.send(completion: Subscribers.Completion<ReachabilityError>.failure(.unableToGetFlags(SCError())))
            }

            self.flags = flags
        }
    }
}

// MARK: - Helper structure for weak reachability

/**
 `ReachabilityWeakifier` weakly wraps the `Reachability` class
 in order to break retain cycles when interacting with CoreFoundation.
 CoreFoundation callbacks expect a pair of retain/release whenever an
 opaque `info` parameter is provided. These callbacks exist to guard
 against memory management race conditions when invoking the callbacks.
 #### Race Condition
 If we passed `SCNetworkReachabilitySetCallback` a direct reference to our
 `Reachability` class without also providing corresponding retain/release
 callbacks, then a race condition can lead to crashes when:
 - `Reachability` is deallocated on thread X
 - A `SCNetworkReachability` callback(s) is already in flight on thread Y
 #### Retain Cycle
 If we pass `Reachability` to CoreFoundtion while also providing retain/
 release callbacks, we would create a retain cycle once CoreFoundation
 retains our `Reachability` class. This fixes the crashes and his how
 CoreFoundation expects the API to be used, but doesn't play nicely with
 Swift/ARC. This cycle would only be broken after manually calling
 `stopNotifier()` — `deinit` would never be called.
 #### ReachabilityWeakifier
 By providing both retain/release callbacks and wrapping `Reachability` in
 a weak wrapper, we:
 - interact correctly with CoreFoundation, thereby avoiding a crash.
 See "Memory Management Programming Guide for Core Foundation".
 - don't alter the public API of `Reachability.swift` in any way
 - still allow for automatic stopping of the notifier on `deinit`.
 */
private class ReachabilityWeakifier {
    weak var reachability: Reachability?
    init(reachability: Reachability) {
        self.reachability = reachability
    }
}
