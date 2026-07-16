---
status: accepted
date: 2026-06-20
---

# DocC documentation, built and deployed from CI

API documentation moves from jazzy (a Ruby gem that generated HTML committed into `docs/`) to **Swift-DocC**, built from doc-comments and deployed to GitHub Pages from CI. We remove jazzy, `scripts/build_docs.sh`, the Ruby dependency, and the committed generated HTML.

DocC is the in-toolchain, Apple-native path: no external runtime, integrates with Xcode's documentation viewer, and lets us stop committing build output to the repo. Consistent with ADR 0006's root-manifest-stays-dependency-free rule, docs are built in CI via `xcodebuild docbuild` + `docc process-archive transform-for-static-hosting` rather than by adding swift-docc-plugin to the published `Package.swift`.

This is recorded so the absence of `docs/` HTML and `build_docs.sh` reads as deliberate rather than an oversight to "restore."

## Consequences

- **All existing jazzy URLs break.** The published paths change shape (`/Classes/SwiftGridView.html` → `/documentation/swiftgridview/...`) with no redirects; accepted, but the 1.0 release notes must call it out.
- **One-time operational cutover in repo settings:** the GitHub Pages source switches from the branch `docs/` folder to GitHub Actions deployment. This is a manual step outside the codebase.
- DocC on a project page (served under `/SwiftGridView/`) requires the static-hosting transform to be run with `--hosting-base-path SwiftGridView`, or every asset 404s.
- The purge removes only generated HTML from `docs/`; `docs/adr/` (these records) stays.
