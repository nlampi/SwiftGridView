---
status: accepted
date: 2026-06-20
---

# swift-format pinned in a side-car Tools package, enforced as a blocking CI check

Formatting is enforced with **swift-format**, pinned to an exact version in a **side-car `Tools/Package.swift`** — a manifest that ships no products and is not referenced by the root `Package.swift`. CI and local runs invoke it identically (`swift run --package-path Tools swift-format lint --strict ...`), and the check is **blocking** in CI.

Two traps drove the mechanism:

1. **Runner drift.** Relying on the toolchain's bundled swift-format means a `macos-latest` Xcode bump silently changes formatting rules and fails unrelated PRs. Pinning makes rule changes an explicit, reviewable dependency bump.
2. **Consumer graph pollution.** Pinning inside the *published* `Package.swift` would force every consumer to resolve swift-format's dependency tree — including swift-syntax, a huge checkout and the single most version-conflict-prone package identity in the ecosystem (any consumer app using macros). SPM requires one swift-syntax version across the whole graph, so a library-side pin can make a consumer's graph unresolvable. The side-car keeps the pin out of consumers' resolution entirely.

This is recorded so a future maintainer neither "simplifies" the pin back to the toolchain binary (trap 1) nor "tidies" the Tools package into the root manifest (trap 2).

## Consequences

- The codebase must be formatted to a clean baseline once; that baseline-format commit lands **separately from any functional change** so the 1.0 diff stays reviewable.
- Bumping swift-format is an explicit, reviewable change to `Tools/Package.swift`, not an ambient runner upgrade.
- The root manifest stays dependency-free.
