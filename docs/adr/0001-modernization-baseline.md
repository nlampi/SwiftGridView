---
status: accepted
date: 2026-06-20
---

# Modernization baseline: iOS 15, swift-tools 6.0, Swift 6 language mode

The 1.0 modernization raises the floor to `swift-tools-version:6.0` / `iOS 15` and adopts the **Swift 6 language mode** (complete strict concurrency). Previously the manifest declared iOS 10 + tools 5.0 while the podspec and README claimed iOS 12 — three inconsistent floors, now unified to one.

We chose Swift 6 language mode because the library has no background concurrency (no GCD, `OperationQueue`, or `Timer`) and `UICollectionView`/`UIView` are already `@MainActor` in the SDK, so the migration is mostly making main-actor isolation explicit on the public protocols rather than untangling data races — the modern guarantee is cheap to obtain here.

## Consequences

- Raising the deployment floor strands consumers on older iOS targets; this is a deliberate, one-way change appropriate to a major version.
- The public surface becomes `@MainActor`-isolated.
