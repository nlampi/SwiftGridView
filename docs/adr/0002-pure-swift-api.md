---
status: accepted
date: 2026-06-20
---

# Pure-Swift public API (drop @objc), breaking 1.0

The datasource and delegate protocols were `@objc public protocol`s using `@objc optional` methods, primarily to support Objective-C consumers and optional-method semantics. For 1.0 we drop `@objc` entirely and make them native Swift protocols, replacing `@objc optional` methods with **default implementations in protocol extensions**.

This is a breaking change — it severs Objective-C interop (the `ObjCExample` is removed) — and is the reason the version moves from `0.7.8` to `1.0.0`. We accepted the break because pure-Swift protocols unlock value types, `Sendable`, generics, and clean Swift 6 main-actor isolation that `@objc` would have blocked, and a pre-1.0 library is the right place to take it.

## Default-implementation policy

The former `@objc optional` methods fall into two tiers, and the defaults differ deliberately:

- **Value-returning optionals** (frozen row/column counts, grid/section header and footer heights): the extension default returns `0`. The call sites already guard with `> 0` (`Sources/SwiftGridView.swift:929-974`), so `0` is behavior-preserving — the feature simply stays off.
- **View-returning optionals** (`gridHeaderViewForColumn`, `gridFooterViewForColumn`, `groupedHeaderViewFor`, `sectionHeaderCellAtIndexPath`, `sectionFooterCellAtIndexPath`): the extension default calls **`fatalError`** with a message naming the method and the feature that requires it (e.g. "you provided a grid header height but did not implement gridHeaderViewForColumn"). There is no sensible view a default can return: these methods are only invoked when the consumer has enabled the corresponding feature, and today's force-calls (`Sources/SwiftGridView.swift:1071-1089`) crash loudly at exactly that moment. A silent default (a bare `SwiftGridReusableView()`) would bypass dequeue/reuse and mask the programmer error as empty headers.

Rejected alternative: splitting each optional feature into a small adopt-if-you-use-it protocol (e.g. `SwiftGridGroupedHeaderDataSource`), which would make the compiler enforce implementation. Cleaner and crash-free, but a larger 1.0 surface redesign; it remains open as a possible 2.0 direction.

## Consequences

- Objective-C consumers can no longer adopt the library; the ObjC example is deleted.
- Call sites stop using optional-chained `?.method?(...)` dispatch; every former optional hook has either a behavior-preserving default or an explicit, documented `fatalError`.
