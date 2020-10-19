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


// MARK: - SwiftGridViewDataSource

/**
 The `SwiftGridViewDataSource` protocol is used much like a UICollectionView or UITableView data source for retrieving all data needed to display the data grid.
 */
@objc public protocol SwiftGridViewDataSource {
    
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
     
     - Parameter dataGridView: The swift grid view instance.
     - Returns: Array of grouped column index sets.
     */
    @objc optional func columnGroupingsForDataGridView(_ dataGridView: SwiftGridView) -> [[Int]]
    
    /**
     Number of rows to display in the provided data grid section.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter section: Current section index.
     - Returns: The number of rows for the current section.
     */
    func dataGridView(_ dataGridView: SwiftGridView, numberOfRowsInSection section: Int) -> Int
    
    /**
     Number of frozen rows in the provided section. Frozen rows start from the top and will be "frozen" in place and not scroll vertically out of view.
     
     - Parameter dataGridView: The swift grid view instance.
     - Returns: Count of frozen columns in the data grid.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, numberOfFrozenRowsInSection section: Int) -> Int
    
    /**
     Number of frozen columns in the data grid. Frozen columns start from the left and will be "frozen" in place and not scroll horizontally out of view.
     
     - Parameter dataGridView: The swift grid view instance.
     - Returns: Count of frozen columns in the data grid.
     */
    @objc optional func numberOfFrozenColumnsInDataGridView(_ dataGridView: SwiftGridView) -> Int
    
    
    // MARK: Cell Methods
    
    /**
     Return the cell content to be displayed in the data grid for the provided indexPath.
     
     - Parameter dataGridView: The swift grid view instance.
     - Paramter indexPath: The Swift Grid extended index path location of the cell.
     - Returns: Cell that has been dequeued and of `SwiftGridCell` type.
     */
    func dataGridView(_ dataGridView: SwiftGridView, cellAtIndexPath indexPath: IndexPath) -> SwiftGridCell
    
    /**
     Return the header view to be displayed in the provided column.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter column: Current column index.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, gridHeaderViewForColumn column: NSInteger) -> SwiftGridReusableView
    
    /**
     Return the header view to be displayed in the provided column grouping
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter columnGrouping: Current grouping.
     - Parameter index: Current grouping index.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, groupedHeaderViewFor columnGrouping: [Int], at index: Int) -> SwiftGridReusableView
    
    /**
     Number of sections to display in the data grid
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter column: Current column index.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, gridFooterViewForColumn column: NSInteger) -> SwiftGridReusableView
    
    /**
     Number of sections to display in the data grid
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section header. Section and Column are provided values, Row is ignored.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, sectionHeaderCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView
    
    /**
     Number of sections to display in the data grid
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section footer. Section and Column are provided values, Row is ignored.
     - Returns: View that has been dequeued and of `SwiftGridReusableView` type.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, sectionFooterCellAtIndexPath indexPath: IndexPath) -> SwiftGridReusableView
}
