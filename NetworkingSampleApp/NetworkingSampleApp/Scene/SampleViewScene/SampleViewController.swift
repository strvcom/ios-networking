//
//  SampleViewController.swift
//  Networking sample app
//
//  Created by Tomas Cejka on 10.03.2021.
//

import UIKit

final class SampleViewController: UIViewController {    
    private let viewModel = SampleViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton()
        button.setTitle("Load users", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(loadUsers), for: .touchUpInside)
        view.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        viewModel.runNetworkingExamples()
    }
    
    @objc private func loadUsers() {
        Task {
            try await viewModel.loadUserList()
        }
    }
}
