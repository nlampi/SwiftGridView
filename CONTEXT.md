# SwiftGridView

A Swift `UICollectionView`-based data grid component for iOS. This glossary fixes the public vocabulary so the same concept is named the same way in code, docs, and delegate/datasource method names — the word "header" in particular is overloaded across three distinct concepts.

## Language

### Core

**Data Grid**:
The two-dimensional grid surface as a whole — sections, rows, and columns of cells with optional headers and footers. The public type that renders it is `SwiftGridView`.
_Avoid_: table, spreadsheet, collection

**SwiftGridView**:
The public UIKit view (`UIView` subclass) that hosts the grid. Backed internally by a `UICollectionView` and a custom layout, but that is an implementation detail callers do not touch.
_Avoid_: grid view, SGView (the old demo name)

**SwiftGrid**:
The public SwiftUI view (a `UIViewRepresentable`) that exposes `SwiftGridView` to SwiftUI. The first-class SwiftUI entry point shipped by the library.
_Avoid_: SGView, SwiftGridViewRepresentable

### Cells and views

**Cell**:
A content unit at a row/column position — the grid's data-bearing element. Public base class `SwiftGridCell`.
_Avoid_: item, tile

**Reusable View**:
A supplementary, non-row view used for headers and footers (grid, section, and grouped). Public base class `SwiftGridReusableView`. Distinct from a Cell, which is only used for row content.
_Avoid_: supplementary view, accessory view

### Headers and footers (three distinct concepts — do not conflate)

**Grid Header / Grid Footer**:
A single header (or footer) spanning the top (or bottom) of the entire grid, organized per column. Pins above all sections.
_Avoid_: table header, global header

**Section Header / Section Footer**:
A header (or footer) that belongs to one section and can stick while that section scrolls.
_Avoid_: group header (means something else here)

**Grouped Header**:
A header that spans a contiguous group of columns (column grouping), sitting above the per-column grid header.
_Avoid_: merged header, spanning header, section header

### Layout features

**Frozen Column / Frozen Row**:
A column (or row) pinned in place so it stays visible while the rest of the grid scrolls.
_Avoid_: sticky column, pinned column, locked column

**Column Grouping**:
A declaration that a contiguous range of columns belongs together, enabling a Grouped Header over them.
_Avoid_: column span, merge
