//
//  DownloadState.swift
//  
//
//  Created by Matej Molnár on 16.01.2023.
//

import Foundation

public enum DownloadState {
    case progress(downloadedBytes: Double, totalBytes: Double)
    case completed(Data?)
    case terminated(resumableData: Data)
}
