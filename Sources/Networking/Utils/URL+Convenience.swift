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

    var fileSize: Int? {
        guard let resources = try? resourceValues(forKeys:[.fileSizeKey]) else {
            return nil
        }
        return resources.fileSize
    }
}
