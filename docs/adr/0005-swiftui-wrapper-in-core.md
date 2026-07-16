---
status: accepted
date: 2026-06-20
---

# SwiftUI wrapper shipped in the core target

The library ships a first-class SwiftUI view (`SwiftGrid`, a `UIViewRepresentable` over `SwiftGridView`) as public API in 1.0, placed in the **core target** rather than as a separate `SwiftGridViewUI` product.

A single target keeps consumption frictionless (one import, the SwiftUI floor is the same iOS 15) and avoids the maintenance overhead of a second product for a small library. We record this because a future maintainer may wonder why SwiftUI code lives in a nominally-UIKit core target instead of an opt-in module — splitting it out later would itself be a breaking change.

## Consequences

- The core target links SwiftUI; the public surface to support forever now includes the `SwiftGrid` representable.
- Promoting SwiftUI to its own product later would break import paths.
