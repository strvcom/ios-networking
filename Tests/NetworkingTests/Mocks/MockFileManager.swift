//
//  MockFileManager.swift
//
//
//  Created by Jan Kodeš on 23.01.2024.
//

import Foundation
import XCTest

/// A subclass of `FileManager` where the file existence is based on a dictionary whose key is the file path.
final class MockFileManager: FileManager {
    enum Function: Equatable {
        case fileExists(path: String)
        case createDirectory(path: String)
        case contentsOfDirectory(path: String)
        case removeItem(path: String)
    }

    /// Mocked or received data
    var dataByFilePath: [String: Data] = [:]

    /// Received functions
    private var functionCallHistory: [Function] = []

    override func fileExists(atPath path: String) -> Bool {
        recordCall(.fileExists(path: path))
        return dataByFilePath[path] != nil
    }

    override func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        recordCall(.createDirectory(path: path))

        // Simulate directory creation by adding an empty entry
        dataByFilePath[path] = Data()
    }

    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        recordCall(.contentsOfDirectory(path: path))

        // Return file names in the specified directory
        return dataByFilePath.keys
            .filter { $0.hasPrefix(path) }
            .map { $0.replacingOccurrences(of: path, with: "") }
    }

    override func removeItem(atPath path: String) throws {
        recordCall(.removeItem(path: path))

        dataByFilePath.removeValue(forKey: path)
    }
}

extension MockFileManager {
    private func recordCall(_ method: Function) {
        functionCallHistory.append(method)
    }

    func verifyFunctionCall(_ expectedMethod: Function, file: StaticString = #file, line: UInt = #line) {
        guard functionCallHistory.contains(where: { $0 == expectedMethod }) else {
            XCTFail("Expected to have called \(expectedMethod). Received: \(functionCallHistory)", file: file, line: line)
            print(functionCallHistory)
            return
        }
    }

    func reset() {
        dataByFilePath = [:]
        functionCallHistory = []
    }
}
