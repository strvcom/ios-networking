## What this app is

- Canonical, reference-quality demo of consuming `Networking` — SwiftUI MVVM, a separate Xcode project (not an SPM target) added to `Networking.xcworkspace` as a local package dependency.
- `swift build`/`swift test` at the package root don't touch this target. From the repository root, build it with `xcodebuild -workspace Networking.xcworkspace -scheme NetworkingSampleApp -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation build`, or run the same scheme in Xcode.

## Not covered by CI

- `.github/workflows/ci.yml` only builds/tests the `Networking` scheme. Since this app is still held to a reference-quality bar, manually build and exercise any scene you change.

## Conventions specific to this app

- Format the app with its local `.swiftformat` configuration and follow the repository's root `.swiftlint.yml` configuration.
- Add endpoints through the existing `API/Requests|Responses|Routers` pattern, not by constructing requests in a View or ViewModel; add new demo features under their own `Scenes/<Feature>/`.
- Keep `StatusCodeProcessor.shared` in any custom `responseProcessors:` array unless the example intentionally demonstrates different status handling.
- `Resources/TestData.xcassets` here is a separate fixture set from `Tests/NetworkingTests/Resources/` — don't conflate them.
