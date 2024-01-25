//
//  FileWriter.swift
//
//
//  Created by Jan Kodeš on 24.01.2024.
//

import Foundation

public protocol FileDataWriterProtocol {
    /// Writes the given data to the specified URL.
    ///
    /// - Parameters:
    ///   - data: The `Data` object that needs to be written to the file.
    ///   - url: The destination `URL` where the data should be written.
    /// - Throws: An error if the data cannot be written to the URL.
    func write(_ data: Data, to url: URL) throws
}

public class FileDataWriter: FileDataWriterProtocol {
    public init() {}

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}
