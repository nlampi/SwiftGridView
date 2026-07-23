# Architecture Decision Records

This directory records the significant, hard-to-reverse decisions behind SwiftGridView, following the [ADR convention](https://github.com/joelparkerhenderson/architecture-decision-record). Each record captures the context, the decision, and why — so a future reader understands *why* the code is the way it is before changing it.

These files are documentation only: nothing in the build reads them, and they are not part of the published package.

## Records

| # | Decision |
|---|----------|
| [0001](0001-modernization-baseline.md) | iOS 15, Swift-tools 6.0, and Swift 6 language mode |
| [0002](0002-pure-swift-api.md) | Pure-Swift API (drop `@objc`), breaking 1.0 |
| [0003](0003-spm-only-distribution.md) | SPM-only distribution (drop CocoaPods) |
| [0004](0004-docc-documentation.md) | DocC documentation, built and deployed from CI |
| [0005](0005-swiftui-wrapper-in-core.md) | SwiftUI wrapper shipped in the core target |
| [0006](0006-swift-format-sidecar-pin.md) | swift-format pinned in a side-car Tools package |

## Adding a record

Copy the shape of an existing record: a short title, a paragraph or two of context and decision, and a `## Consequences` section when there are non-obvious downstream effects. Number it sequentially and add a row above.
