# ``SwiftGridView``

A fully customizable data grid for iOS, built on `UICollectionView`.

## Overview

`SwiftGridView` renders two-dimensional grids of sections, rows, and columns with headers, footers, frozen rows and columns, and grouped headers. It is driven by a datasource and delegate, much like `UITableView` or `UICollectionView`, and works in both UIKit and SwiftUI.

```swift
import SwiftGridView

let grid = SwiftGridView(frame: view.bounds)
grid.dataSource = self  // SwiftGridViewDataSource
grid.delegate = self    // SwiftGridViewDelegate
grid.register(MyCell.self, forCellWithReuseIdentifier: MyCell.reuseIdentifier())
view.addSubview(grid)
```

In SwiftUI, use ``SwiftGrid`` with the same datasource and delegate objects:

```swift
SwiftGrid(dataSource: model, delegate: model) { grid in
    grid.register(MyCell.self, forCellWithReuseIdentifier: MyCell.reuseIdentifier())
}
```

New to the component? Start with <doc:GridAnatomy> to learn the vocabulary the rest of the API uses.

## Topics

### Essentials

- <doc:GridAnatomy>
- ``SwiftGridView/SwiftGridView``
- ``SwiftGrid``

### Providing Content

- ``SwiftGridViewDataSource``
- ``SwiftGridViewDelegate``

### Cells and Reusable Views

- ``SwiftGridCell``
- ``SwiftGridReusableView``
- ``SwiftGridReusableViewDelegate``

### Element Kinds

- ``SwiftGridElementKindHeader``
- ``SwiftGridElementKindGroupedHeader``
- ``SwiftGridElementKindSectionHeader``
- ``SwiftGridElementKindFooter``
- ``SwiftGridElementKindSectionFooter``
