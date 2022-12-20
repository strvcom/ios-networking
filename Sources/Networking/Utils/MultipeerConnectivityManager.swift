//
//  MultipeerConnectivityManager.swift
//  ios-networking-app
//
//  Created by Jaroslav Janda on 12.10.2021.
//

#if os(watchOS)
    import os
#else
    import OSLog
#endif

import Foundation
import Combine
import MultipeerConnectivity

public class MultipeerConnectivityManager: NSObject, ObservableObject {
    public static let shared = MultipeerConnectivityManager()
    
    private static let service = "networking-jobs"
    private static let macOSAppDisplayName = "networking-macos-app"
    
    private var peers = Set<MCPeerID>()
    private let myPeerId: MCPeerID = {
        #if targetEnvironment(simulator)
        return MCPeerID(displayName: UIDevice.current.name + "(Simulator)")
        #else
        return MCPeerID(displayName: UIDevice.current.name)
        #endif
    }()
    
    private lazy var session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
    private lazy var nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
        peer: myPeerId,
        discoveryInfo: nil,
        serviceType: MultipeerConnectivityManager.service
    )
    
    private var buffer: [EndpointRequestStorageModel] = .init()
    
    private override init() {
        super.init()
        session.delegate = self
        nearbyServiceAdvertiser.delegate = self
        nearbyServiceAdvertiser.startAdvertisingPeer()
    }

    func send(model: EndpointRequestStorageModel) {
        guard let peerId = peers.first(where: { $0.displayName ==  Self.macOSAppDisplayName }) else {
            buffer.append(model)
            return
        }
        
        do {
            try send([model], to: peerId)
        } catch {
            os_log("❌ Failed to send request data via multipeer connection")
            buffer.append(model)
        }
    }
}

private extension MultipeerConnectivityManager {
    func send(_ model: [EndpointRequestStorageModel], to peer: MCPeerID) throws {
        let data = try JSONEncoder().encode(model)
        try session.send(data, toPeers: [peer], with: .reliable)
        buffer.removeAll()
        os_log("🎈 Request data were successfully sent via multipeer connection")
    }
}

extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(true, self.session)
    }
}

extension MultipeerConnectivityManager: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            peers.insert(peerID)
            if !buffer.isEmpty {
                try? send(buffer, to: peerID)
            }
            print("Connected")
        case .notConnected:
            print("Not connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting to: \(peerID.displayName)")
        @unknown default:
            print("Unknown state: \(state)")
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
