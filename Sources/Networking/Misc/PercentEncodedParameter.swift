//
//  PercentEncodedParameter.swift
//
//
//  Created by Matej Molnár on 01.01.2024.
//

import Foundation

/// URL request query parameter that represents a value which will not be subjected to default percent encoding during URLRequest construction.
///
/// This type is useful in case you want to override the default percent encoding of some special characters with accordance to RFC3986.
///
/// Usage example:
///
///     var urlParameters: [String: Any]? {
///         ["specialCharacter": ">"]
///     }
///
///     // Request URL "https://test.com?specialCharacter=%3E"
///
///     var urlParameters: [String: Any]? {
///         ["specialCharacter": PercentEncodedParameter(">")]
///     }
///
///     // Request URL "https://test.com?specialCharacter=>"
///
public struct PercentEncodedParameter {
    // Library provides plus sign percent encoding
    public enum PercentEncoding {
        case plusSign
        case custom
    }

    let value: String
    let percentEncoding: PercentEncoding

    public init(_ value: String, percentEncoding: PercentEncoding = .plusSign) {
        self.value = value
        self.percentEncoding = percentEncoding
    }
}
