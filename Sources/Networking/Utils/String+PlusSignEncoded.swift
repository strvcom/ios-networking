//
//  String+PlusSignEncoded.swift
//
//
//  Created by Tomas Cejka on 17.02.2024.
//

import Foundation

public extension String {
    /// Help method to allow custom + sign encoding, more in ```CustomEncodedParameter```
    func plusSignEncoded() -> Self? {
        self
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%2B")
    }
}
