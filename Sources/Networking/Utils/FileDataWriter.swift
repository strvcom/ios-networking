//
//  FileDataWriter.swift
//
//
//  Created by Jan Kodeš on 24.01.2024.
//

import Foundation

/// A protocol defining an interface for writing data to a file.
public protocol FileDataWriting {
    /// Writes the given data to the specified URL.
    ///
    /// - Parameters:
    ///   - data: The `Data` object that needs to be written to the file.
    ///   - url: The destination `URL` where the data should be written.
    /// - Throws: An error if the data cannot be written to the URL.
    func write(_ data: Data, to url: URL) throws
}


/// A class that implements data writing functionality.
public class FileDataWriter: FileDataWriting {
    public init() {}

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }
}
