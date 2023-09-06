//
//  ContentView.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 28.01.2023.
//

import SwiftUI

enum NetworkingFeature: String, Hashable, CaseIterable {
    case authorization
    case downloads
    case uploads
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(NetworkingFeature.allCases, id: \.self) { feature in
                    NavigationLink(feature.rawValue.capitalized, value: feature)
                }
            }
            .navigationTitle("Examples")
            .navigationDestination(for: NetworkingFeature.self) { feature in
                switch feature {
                case .authorization:
                    AuthorizationView()
                case .downloads:
                    DownloadsView()
                case .uploads:
                    UploadsView()
                }
            }
        }
    }
}
