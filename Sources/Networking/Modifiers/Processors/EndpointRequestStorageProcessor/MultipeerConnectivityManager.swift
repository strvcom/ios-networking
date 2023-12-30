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

// @preconcurrency suppresses a swift concurrency warning: Non-sendable type ...
@preconcurrency import MultipeerConnectivity

@NetworkingActor
public final class MultipeerConnectivityManager: NSObject {
    public static let service = "networking-jobs"
    public static let macOSAppDisplayName = "networking-macos-app"
    
    private var buffer: [EndpointRequestStorageModel]
    private var peers = Set<MCPeerID>()

    private let session: MCSession
    private let nearbyServiceAdvertiser: MCNearbyServiceAdvertiser

    init(
        buffer: [EndpointRequestStorageModel],
        deviceName: String
    ) {
        self.buffer = buffer

        let myPeerId: MCPeerID = {
            #if targetEnvironment(simulator)
            return MCPeerID(displayName: "Simulator - " + deviceName)
            #else
            return MCPeerID(displayName: deviceName)
            #endif
        }()

        self.session = MCSession(
            peer: myPeerId,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: MultipeerConnectivityManager.service
        )

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

    func stateChanged(_ state: MCSessionState, for peerID: MCPeerID) {
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
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated public func advertiser(
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
    nonisolated public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task {
            await stateChanged(state, for: peerID)
        }
    }
    
    nonisolated public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    nonisolated public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
