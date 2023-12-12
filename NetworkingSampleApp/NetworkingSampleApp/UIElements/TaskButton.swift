//
//  TaskButton.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 11.12.2023.
//

import SwiftUI

struct TaskButton: View {
    enum Config {
        case play, pause, cancel, retry

        var imageName: String {
            switch self {
            case .play: "play"
            case .pause: "pause"
            case .retry: "repeat"
            case .cancel: "x"
            }
        }

        var color: Color {
            switch self {
            case .play, .pause, .retry:
                .blue
            case .cancel: 
                .red
            }
        }
    }

    let config: Config
    let action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                Image(systemName: config.imageName)
                    .symbolVariant(.circle.fill)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(config.color)
            }
        )
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}
