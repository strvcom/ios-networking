//
//  FileDataWriterSpy.swift
//
//
//  Created by Jan Kodeš on 24.01.2024.
//

import Foundation
import Networking

class FileDataWriterSpy: FileDataWriterProtocol {
    var writeClosure: (() -> Void)?
    private(set) var writeCalled = false
    private(set) var receivedData: Data?
    private(set) var receivedURL: URL?

    func write(_ data: Data, to url: URL) throws {
        writeCalled = true
        receivedData = data
        receivedURL = url
        try data.write(to: url)

        writeClosure?()
    }
}
