# Grid Anatomy

Learn the pieces that make up a grid and the vocabulary the API uses.

## Overview

A grid is a two-dimensional surface of sections, rows, and columns. The word "header" in particular means three distinct things in this API, so it is worth getting the terms straight before you start.

### Cells and reusable views

There are two kinds of content in a grid, and they map to two base classes:

- A **cell** is the data-bearing content at a single row and column position. Subclass ``SwiftGridCell`` for row content.
- A **reusable view** is a supplementary view used for headers and footers of every kind. Subclass ``SwiftGridReusableView`` for those.

Both are dequeued and reused exactly as in `UICollectionView`. Register your classes or nibs up front, then dequeue them in the corresponding datasource methods.

### The three kinds of header

These are separate concepts — do not conflate them:

- A **grid header** (and **grid footer**) spans the top (or bottom) of the entire grid, organized per column. It pins above all sections. Provided by ``SwiftGridViewDataSource/dataGridView(_:gridHeaderViewForColumn:)``.
- A **section header** (and **section footer**) belongs to a single section and can stick while that section scrolls. Provided by ``SwiftGridViewDataSource/dataGridView(_:sectionHeaderCellAtIndexPath:)``.
- A **grouped header** spans a contiguous group of columns, sitting above the per-column grid header. Provided by ``SwiftGridViewDataSource/dataGridView(_:groupedHeaderViewFor:at:)`` when you return column groupings.

Each header and footer is displayed only when the delegate returns a height greater than zero for it.

### Frozen rows and columns

A **frozen column** stays pinned to the leading edge while the rest of the grid scrolls horizontally; a **frozen row** stays pinned to the top of its section while the grid scrolls vertically. Frozen columns start from the left and frozen rows start from the top of each section. Return counts from ``SwiftGridViewDataSource/numberOfFrozenColumnsInDataGridView(_:)`` and ``SwiftGridViewDataSource/dataGridView(_:numberOfFrozenRowsInSection:)``.

### Column groupings

A **column grouping** declares that a contiguous range of columns belongs together, enabling a grouped header to span them. Return an array of `[first, last]` column-index pairs from ``SwiftGridViewDataSource/columnGroupingsForDataGridView(_:)``. Columns cannot belong to more than one grouping. For example, `[[1, 4], [5, 8]]` creates two groups.

### Index paths

Grid positions use an extended `IndexPath`. Build one with `IndexPath(forSGRow:atColumn:inSection:)` and read its components with `sgRow`, `sgColumn`, and `sgSection` rather than the raw `item`/`section`, which are used internally for the backing `UICollectionView`.

## Topics

### Related Types

- ``SwiftGridCell``
- ``SwiftGridReusableView``
- ``SwiftGridViewDataSource``
- ``SwiftGridViewDelegate``
