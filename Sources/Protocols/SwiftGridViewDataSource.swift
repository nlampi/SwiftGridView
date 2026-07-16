// SwiftGridViewDataSource.swift
// Copyright (c) 2016 - Present Nathan Lampi (http://nathanlampi.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit

// MARK: - SwiftGridViewDataSource

/**
 The `SwiftGridViewDataSource` protocol is used much like a UICollectionView or UITableView data source for retrieving all data needed to display the data grid.

 Methods with default implementations are optional. Feature-enabling methods (frozen rows/columns, column groupings) default to "feature off". View-providing
 methods default to a `fatalError`: they are only ever called once the corresponding feature is enabled, at which point not implementing them is a programmer error.
 */
@MainActor
public protocol SwiftGridViewDataSource: AnyObject {

    // MARK: Count methods

    /**
     Count of sections to display in the data grid.

     - Parameter dataGridView: The swift grid view instance.
     - Returns: The number of sections within the data grid.
     */
    func numberOfSectionsInDataGridView(_ dataGridView: SwiftGridView) -> Int

    /**
     Count of columns to display in the data grid.

     - Parameter dataGridView: The swift grid view instance.
     - Returns: The number of columns within the data grid.
     */
    func numberOfColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int

    /**
     The grouping settings to use for the data grid. Expects an array of grouped column index sets for the first and last column index
     in each grouping. Columns cannot be included in multiple groupings.
     Example: [[1,4], [5,8]]

     Defaults to no groupings.

     - Parameter dataGridView: The swift grid view instance.
     - Returns: Array of grouped column index sets.
     */
    func columnGroupingsForDataGridView(_ dataGridView: SwiftGridView) -> [[Int]]

    /**
     Number of rows to display in the provided data grid section.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter section: Current section index.
     - Returns: The number of rows for the current section.
     */
    func dataGridView(_ dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int

    /**
     Number of frozen rows in the provided section. Frozen rows start from the top and will be "frozen" in place and not scroll vertically out of view.

     Defaults to no frozen rows.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter section: Current section index.
     - Returns: Count of frozen rows in the section.
     */
    func dataGridView(_ dataGridView: SwiftGridView, numberOfFrozenRowsInSection section: Int) -> Int

    /**
     Number of frozen columns in the data grid. Frozen columns start from the left and will be "frozen" in place and not scroll horizontally out of view.

     Defaults to no frozen columns.

     - Parameter dataGridView: The swift grid view instance.
     - Returns: Count of frozen columns in the data grid.
     */
    func numberOfFrozenColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int

    // MARK: Cell Methods

    /**
     Return the cell content to be displayed in the data grid for the provided indexPath.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: The Swift Grid extended index path location of the cell.
     - Returns: Cell that has been dequeued and of `SwiftGridCell` type.
     */
    func dataGridView(_ dataGridView: SwiftGridView, cellAtIndexPath indexPath: IndexPath) -> SwiftGridCell

    /**
     Return the header view to be displayed in the provided column.

     Required when the delegate provides a grid header height greater than zero.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter column: Current column index.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: Int) -> SwiftGridReusableView

    /**
     Return the header view to be displayed in the provided column grouping.

     Required when column groupings are provided.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter columnGrouping: Current grouping.
     - Parameter index: Current grouping index.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    func dataGridView(_ dataGridView: SwiftGridView, groupedHeaderViewFor columnGrouping: [Int], at index: Int) -> SwiftGridReusableView

    /**
     Return the footer view to be displayed in the provided column.

     Required when the delegate provides a grid footer height greater than zero.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter column: Current column index.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    func dataGridView(_ dataGridView: SwiftGridView, gridFooterViewForColumn column: Int) -> SwiftGridReusableView

    /**
     Return the section header view to be displayed at the provided index path.

     Required when the delegate provides a section header height greater than zero.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section header. Section and Column are provided values, Row is ignored.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    func dataGridView(_ dataGridView: SwiftGridView, sectionHeaderCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView

    /**
     Return the section footer view to be displayed at the provided index path.

     Required when the delegate provides a section footer height greater than zero.

     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section footer. Section and Column are provided values, Row is ignored.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    func dataGridView(_ dataGridView: SwiftGridView, sectionFooterCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView
}

// MARK: - Default Implementations

extension SwiftGridViewDataSource {

    public func columnGroupingsForDataGridView(_ dataGridView: SwiftGridView) -> [[Int]] {
        return []
    }

    public func dataGridView(_ dataGridView: SwiftGridView, numberOfFrozenRowsInSection section: Int) -> Int {
        return 0
    }

    public func numberOfFrozenColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int {
        return 0
    }

    public func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: Int) -> SwiftGridReusableView {
        fatalError("SwiftGridView: a grid header height was provided but `dataGridView(_:gridHeaderViewForColumn:)` is not implemented.")
    }

    public func dataGridView(_ dataGridView: SwiftGridView, groupedHeaderViewFor columnGrouping: [Int], at index: Int) -> SwiftGridReusableView {
        fatalError("SwiftGridView: column groupings were provided but `dataGridView(_:groupedHeaderViewFor:at:)` is not implemented.")
    }

    public func dataGridView(_ dataGridView: SwiftGridView, gridFooterViewForColumn column: Int) -> SwiftGridReusableView {
        fatalError("SwiftGridView: a grid footer height was provided but `dataGridView(_:gridFooterViewForColumn:)` is not implemented.")
    }

    public func dataGridView(_ dataGridView: SwiftGridView, sectionHeaderCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView {
        fatalError("SwiftGridView: a section header height was provided but `dataGridView(_:sectionHeaderCellAtIndexPath:)` is not implemented.")
    }

    public func dataGridView(_ dataGridView: SwiftGridView, sectionFooterCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView {
        fatalError("SwiftGridView: a section footer height was provided but `dataGridView(_:sectionFooterCellAtIndexPath:)` is not implemented.")
    }
}
