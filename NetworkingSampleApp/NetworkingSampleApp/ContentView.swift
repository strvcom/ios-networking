//
//  ContentView.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 28.01.2023.
//

import SwiftUI

enum NetworkingCase: String, Hashable, CaseIterable {
    case authorization
    case downloads
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(NetworkingCase.allCases, id: \.self) { screen in
                    NavigationLink(screen.rawValue.capitalized, value: screen)
                }
            }
            .navigationTitle("Examples")
            .navigationDestination(for: NetworkingCase.self) { screen in
                switch screen {
                case .authorization:
                    AuthorizationView()
                case .downloads:
                    DownloadsView()
                }
            }
        }
    }
}
