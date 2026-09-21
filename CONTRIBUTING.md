# Contributing to Networking

Guidance for working **on** this package. If you are using the SDK in an app, read the [README](README.md) or [DocC overview](Sources/Networking/Documentation.docc/Documentation.md).

Networking is STRV's Swift package for HTTP API clients: a protocol-oriented request/response pipeline on native `URLSession` and Swift concurrency.

Nested `AGENTS.md` files are authoritative for constraints local to `NetworkingSampleApp/`, `Sources/Networking/Core/`, and `Sources/Networking/Modifiers/`.

## Architecture and public behavior

- The request pipeline is `Requestable` → `RequestAdapting` → `ResponseProviding` (normally `URLSession`) → `ResponseProcessing`; exhausted retries and other failures flow through `ErrorProcessing`.
- Add cross-cutting behavior through `RequestAdapting`, `ResponseProcessing`, `ErrorProcessing`, or `RequestInterceptor` and inject it through the appropriate manager initializer rather than modifying manager internals.
- Manager APIs and pipeline protocols are isolated to `NetworkingActor`. Preserve actor isolation and `Sendable` value semantics; use `@unchecked Sendable` only where an existing wrapper for non-`Sendable` Foundation state requires it.
- The package does not provide global shared manager instances. Applications own their managers; the sample app demonstrates an app-local shared extension.
- Passing `responseProcessors:` replaces the default `[StatusCodeProcessor.shared]`. Preserve the processor unless intentionally changing status handling; `acceptableStatusCodes` defaults to `200..<400`.
- This SDK has external consumers. Avoid breaking public APIs without strong justification, prefer deprecation over removal, and make public failure paths throw instead of trapping or force-casting.

## Build, test, and lint

- CI-parity macOS check: `xcodebuild clean test -scheme "Networking" -destination 'platform=macOS' -skipPackagePluginValidation`.
- CI also tests iOS; use `.github/workflows/ci.yml` as the authority for the pinned Xcode version and simulator destination.
- Iterate faster with `swift build` and `swift test`.
- SwiftLint runs as a build-tool plugin on every build; do not add a separate lint step.
- The first local build may prompt for SwiftLintBuildToolPlugin trust. `-skipPackagePluginValidation`, as used in CI, skips that prompt non-interactively.
- watchOS is declared but is not exercised by CI or another script; do not describe it as verified.

## Documentation

- Update `README.md` and `Sources/Networking/Documentation.docc/Documentation.md` together whenever public API behavior or examples change.
- Never hand-edit `docs/`; generate it with `./generate_docs.sh`.

## Testing

- XCTest lives in `Tests/NetworkingTests/`. Recorded fixtures under `Tests/NetworkingTests/Resources/TestData.xcassets` are produced by `EndpointRequestStorageProcessor`, not hand-written.
- Tests that call actor-isolated APIs must themselves be `@NetworkingActor`-isolated.
