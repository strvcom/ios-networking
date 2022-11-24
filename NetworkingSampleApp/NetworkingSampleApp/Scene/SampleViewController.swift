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
        
        Task {
            do {
                let response: SampleUsersResponse = try await apiManager.request(
                    SampleUserRouter.users(page: 2)
                )
                
                print(response)
            }
        }
    }
}
