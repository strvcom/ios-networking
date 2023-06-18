//
//  URL+Convenience.swift
//  
//
//  Created by Tony Ngo on 18.06.2023.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    var mimeType: String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }

    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
