//
//  SampleViewController.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 10.03.2021.
//

import UIKit
import OSLog

final class SampleViewController: UIViewController {    
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var refreshButton: UIButton!
    
    private let viewModel = SampleViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        viewModel.runNetworkingExamples()
    }
}

private extension SampleViewController {
    func setup() {
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(refresh), for: .touchUpInside)
    }
}

// MARK: Actions
private extension SampleViewController {
    @objc func refresh() {
        Task {
            do {
                try await viewModel.checkAuthorizationStatus()
            } catch {
                os_log("%{public}@", log: OSLog.default, type: .info, error.localizedDescription)
            }
        }
    }
    
    @objc func login() {
        Task {
            do {
                try await viewModel.login(
                    email: SampleAPIConstants.validEmail,
                    password: SampleAPIConstants.validPassword
                )
            } catch {
                os_log("%{public}@", log: OSLog.default, type: .info, String(describing: error))
            }
        }
    }
}
