---
status: accepted
date: 2026-06-20
---

# SPM-only distribution (drop CocoaPods)

Swift Package Manager becomes the sole supported distribution channel. We remove the podspec, all `Podfile`s, the committed `Pods/` directories, the top-level `.xcodeproj`/`.xcworkspace`, and convert the example apps to reference the package via a local SPM path.

CocoaPods is in long-term decline and maintaining a parallel podspec, workspace, and committed Pods adds friction and repo cruft with little remaining benefit; SPM is the native, first-class toolchain path. The cut is made cleanly at the 1.0 break rather than via a deprecation period.

## Consequences

- Existing `pod 'SwiftGridView'` users must migrate to SPM; there is no grace release. No deprecation action is needed on our side — the CocoaPods trunk wind-down already surfaces deprecation for all pods.
- The `.xcworkspace` (which existed mainly to marry the library with CocoaPods/examples) is gone — Xcode opens `Package.swift` directly.
