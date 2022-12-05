//
//  SampleViewController.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 10.03.2021.
//

import UIKit
import Networking

final class SampleViewController: UIViewController {
    private let apiManager = APIManager(urlSession: URLSession.shared)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runNetworkingExamples()
    }
}

// MARK: Networking examples using sample API
private extension SampleViewController {
    func runNetworkingExamples() {
        Task {
            do {
                try await loadUserList()                
            } catch {
                print(error)
            }
        }
    }
    
    func loadUserList() async throws {
        let response: SampleUsersResponse = try await apiManager.request(
            SampleUserRouter.users(page: 2)
        )
        print(response)
    }
}
