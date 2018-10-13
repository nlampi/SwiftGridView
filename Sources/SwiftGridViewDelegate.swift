// SwiftGridView.swift
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


// MARK: - SwiftGridViewDelegate

/**
 The `SwiftGridViewDelegate` protocol is used much like a UICollectionView or UITableView delegate for handling interactions and sizing of the data grid.
 */
@objc public protocol SwiftGridViewDelegate {
    
    // MARK: Sizing
    
    /**
     Returns the width of the specified column in the data grid.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter columnIndex: Current column index.
     - Returns: Width to be used for all views and cells in the provided column.
     */
    func dataGridView(_ dataGridView: SwiftGridView, widthOfColumnAtIndex columnIndex: Int) -> CGFloat
    
    /**
     Returns the height of the specified row in the data grid.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the row. Section and Row are provided values, Column is ignored.
     - Returns: Height to be used for all cells in the provided row.
     */
    func dataGridView(_ dataGridView: SwiftGridView, heightOfRowAtIndexPath indexPath: IndexPath) -> CGFloat
    
    
    // MARK: Header Methods
    
    /**
     Returns the height of the header views in the data grid.
     
     - Parameter dataGridView: The swift grid view instance.
     - Returns: Height to be used for all views in the grid header.
     */
    @objc optional func heightForGridHeaderInDataGridView(_ dataGridView: SwiftGridView) -> CGFloat
    
    /**
     Called when a header view is selected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the header.  Column is the provided value, Row and Section are ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didSelectHeaderAtIndexPath indexPath: IndexPath)
    
    /**
     Called when a header view is deselected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the header.  Column is the provided value, Row and Section are ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didDeselectHeaderAtIndexPath indexPath: IndexPath)
    
    /**
     Called when a grouped header view is selected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter index: Grouped header index.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didSelectGroupedHeader columnGrouping: [Int], at index: Int)
    
    /**
     Called when a grouped header view is deselected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter index: Grouped header index.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didDeselectGroupedHeader columnGrouping: [Int], at index: Int)
    
    
    // MARK: Footer Methods
    
    /**
     Returns the height of the footer views in the data grid.
     
     - Parameter dataGridView: The swift grid view instance.
     - Returns: Height to be used for all views in the grid footer.
     */
    @objc optional func heightForGridFooterInDataGridView(_ dataGridView: SwiftGridView) -> CGFloat
    
    /**
     Called when a footer view is deselected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the footer.  Column is the provided value, Row and Section are ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didSelectFooterAtIndexPath indexPath: IndexPath)
    
    /**
     Called when a footer view is deselected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the footer.  Column is the provided value, Row and Section are ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didDeselectFooterAtIndexPath indexPath: IndexPath)
    
    
    // MARK: Section Header Methods
    
    /**
     Returns the height of the header views in the provided data grid section.
     
     - Parameter dataGridView: The swift grid view instance.
     - Returns: Height to be used for all views in the section's header.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, heightOfHeaderInSection section: Int) -> CGFloat
    
    /**
     Called when a section header view is selected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section header.  Section and Column are provided, Row is ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didSelectSectionHeaderAtIndexPath indexPath: IndexPath)
    
    /**
     Called when a section header view is deselected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section header.  Section and Column are provided, Row is ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didDeselectSectionHeaderAtIndexPath indexPath: IndexPath)
    
    
    // MARK: Section Footer Methods
    
    /**
     Returns the height of the footer views in the provided data grid section.
     
     - Parameter dataGridView: The swift grid view instance.
     - Returns: Height to be used for all views in the section's footer.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, heightOfFooterInSection section: Int) -> CGFloat
    
    /**
     Called when a section footer view is selected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section footer.  Section and Column are provided, Row is ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didSelectSectionFooterAtIndexPath indexPath: IndexPath)
    
    /**
     Called when a section footer view is deselected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the section footer.  Section and Column are provided, Row is ignored.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didDeselectSectionFooterAtIndexPath indexPath: IndexPath)
    
    
    // MARK: Cell Methods
    
    /**
     Called when a cell is selected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the selected cell.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didSelectCellAtIndexPath indexPath: IndexPath)
    
    /**
     Called when a cell is deselected.
     
     - Parameter dataGridView: The swift grid view instance.
     - Parameter indexPath: Current Swift Grid index path for the deselected cell.
     */
    @objc optional func dataGridView(_ dataGridView: SwiftGridView, didDeselectCellAtIndexPath indexPath: IndexPath)
}
