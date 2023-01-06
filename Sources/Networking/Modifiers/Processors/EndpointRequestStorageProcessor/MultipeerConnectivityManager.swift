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

import MultipeerConnectivity

open class MultipeerConnectivityManager: NSObject {
    private static let service = "networking-jobs"
    private static let macOSAppDisplayName = "networking-macos-app"
    
    private var buffer: [EndpointRequestStorageModel]
    private var peers = Set<MCPeerID>()
    private lazy var myPeerId: MCPeerID = {
        #if os(macOS)
        let deviceName = Host.current().localizedName ?? "macOS"
        #else
        let deviceName = UIDevice.current.name
        #endif
        
        #if targetEnvironment(simulator)
        return MCPeerID(displayName: "Simulator - " + deviceName)
        #else
        return MCPeerID(displayName: deviceName)
        #endif
    }()
    
    private lazy var session = MCSession(
        peer: myPeerId,
        securityIdentity: nil,
        encryptionPreference: .none
    )
    private lazy var nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
        peer: myPeerId,
        discoveryInfo: nil,
        serviceType: MultipeerConnectivityManager.service
    )
    
    init(buffer: [EndpointRequestStorageModel]) {
        self.buffer = buffer
        
        super.init()
         
        session.delegate = self
        nearbyServiceAdvertiser.delegate = self
        nearbyServiceAdvertiser.startAdvertisingPeer()
    }
}

// MARK: - Public functions
extension MultipeerConnectivityManager {
    func send(model: EndpointRequestStorageModel) {
        buffer.append(model)
        
        guard let peerId = peers.first(where: { $0.displayName ==  Self.macOSAppDisplayName }) else {
            return
        }
        
        sendBuffer(to: peerId)
    }
}

// MARK: - Private functions
private extension MultipeerConnectivityManager {
    func sendBuffer(to peerId: MCPeerID) {
        do {
            try send(buffer, to: peerId)
        } catch {
            os_log("❌ Failed to send requests data via multipeer connection \(error)")
        }
    }
    
    func send(_ model: [EndpointRequestStorageModel], to peerId: MCPeerID) throws {
        let data = try JSONEncoder().encode(model)
        try session.send(data, toPeers: [peerId], with: .reliable)
        buffer.removeAll()
        os_log("🎈 Request data were successfully sent via multipeer connection")
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
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

// MARK: - MCSessionDelegate
extension MultipeerConnectivityManager: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            peers.insert(peerID)
            if !buffer.isEmpty {
                sendBuffer(to: peerID)
            }
        case .notConnected, .connecting:
            peers.remove(peerID)
        @unknown default:
            break
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
