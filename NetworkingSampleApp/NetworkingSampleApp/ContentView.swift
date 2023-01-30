//
//  ContentView.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 28.01.2023.
//

import SwiftUI

enum Sample: String, Hashable, CaseIterable {
    case authorization
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(Sample.allCases, id: \.self) { screen in
                    NavigationLink(screen.rawValue.capitalized, value: Sample.authorization)
                }
            }
            .navigationTitle("Samples")
            .navigationDestination(for: Sample.self) { screen in
                switch screen {
                case .authorization: AuthorizationView()
                }
            }
        }
    }
}
