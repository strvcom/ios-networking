//
//  ViewController.swift
//  networking sample app
//
//  Created by Tomas Cejka on 10.03.2021.
//

import UIKit

class ViewController: UIViewController {
    private lazy var sampleAPI = SampleAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        // run sample API
        sampleAPI.runSamples()
    }
}
