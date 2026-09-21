# Networking (STRV)

Swift package for HTTP APIs built on native `URLSession` and Swift concurrency. Endpoints are `Requestable` values executed by API, download, or upload managers through injectable request, response, and error-processing pipelines.

## Working in this repository

- Before changing package code, read [CONTRIBUTING.md](CONTRIBUTING.md). It is the source of truth for architecture constraints, public API compatibility, build/test/lint commands, and documentation requirements.
- For consumer-facing API behavior and examples, use the [README](README.md), [DocC overview](Sources/Networking/Documentation.docc/Documentation.md), and [published API reference](https://strvcom.github.io/ios-networking/documentation/networking/).
- `NetworkingSampleApp/` is the reference integration and has its own build and architecture guidance.
- Directory-specific `AGENTS.md` files add only the constraints relevant to code under their directory; follow the nearest applicable file together with this root guidance.
