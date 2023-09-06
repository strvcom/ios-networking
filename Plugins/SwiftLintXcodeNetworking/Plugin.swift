//
//  Plugin.swift
//  
//
//  Created by Tomas Cejka on 06.09.2023.
//

import PackagePlugin

@main
struct SwiftLintPlugins: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        return [
            .buildCommand(
                displayName: "Linting \(target.name)",
                executable: try context.tool(named: "swiftlint").path,
                arguments: [
                    "lint",
                    "--config",
                    "\(target.directory.string)/.swiftlint.yml",
                    target.directory.string   // only lint the files in the target directory
                ],
                environment: [:]
            )
        ]
    }
}
