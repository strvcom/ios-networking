//
//  File.swift
//  
//
//  Created by Matej Molnár on 20.12.2023.
//

import Foundation

/// A type which represents data that can be uploaded.
public enum UploadType {
    /// - data: The data to send to the server.
    /// - contentType: Content type which should be set as a header in the upload request.
    case data(Data, contentType: String)
    /// The URL of a file which should be sent to the server.
    case file(URL)
    /// - data: The multipart form data to upload.
    /// - sizeThreshold: The size threshold, in bytes, above which the data is streamed from disk rather than being loaded into memory all at once.
    case multipart(data: MultipartFormData, sizeThreshold: UInt64)
}
